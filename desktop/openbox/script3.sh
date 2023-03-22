#!/bin/bash
#
# ./customizations.sh user customizations for openbox desktop
#
# Dependencies: none
#
### CODE:

### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING ###########
# shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


############################################################
### DECLARE FUNCTIONS
############################################################

## ERROR HANDLING ## Usage: <command> || die "<description>"
out () { printf "$1 $2\n" "${@:3}"; }
error () { out "==> ERROR:" "$@"; } >&2
die () { error "$@"; exit 1; }
# Messages
warning () { out "==> WARNING:" "$@"; } >&2
msg () { out "==>" "$@"; }
msg2 () { out "  ->" "$@"; }

############################################################
### MAIN CODE ##############################################
############################################################

## welcome message
echo "Wellcome to OPENBOX customization:"
read -p "==> Start $0 to customize the new desktop?[Y/n]" answer
[[ "${answer:-Y}" =~ ^([nN])$ ]] && exit 0
echo "--> Starting $0 to cutomize OPENBOX window manager"
unset answer

## Basic Verifications
# user privileges
if (( "$EUID" == 0 )); then
  die "Do not run ./$0 as root!"
fi    

# if no internet connection, add a new one
if ! wget -q --spider https://google.com; then
  printf "%s\n" "Internet Connection NOT Detected but REQUIRED"
  # if lsblk -f | awk '/mmc.*p1/{print $7}'; then
  # read -p "Please insert the device /dev/mmcblk0p1 and press any key."
  sudo mkdir -p /tmp/raom && sudo mount /dev/mmcblk0p1 $_
  wifi_connections || die "Can not run $_"
fi

## source dependencies
my_file=~/.bashrc
if [[ -r "${my_file}" ]] && [[ -f "${my_file}" ]]; then
  source "${my_file}"
else
  die "${my_file} could not be sourced"
fi
unset my_file

## measure time
SECONDS=0

## backup desktop configuration files before changes  
for folder in $HOME/.{config,local}; do
  if [[ -d "${folder}" ]]; then
    mkdir -p "${folder}_bk" || die
    cp -r "${folder}"/* "${folder}_bk" || die
  fi
done

## Install Dependencies
# sudo pacman -Syu --needed --noconfirm \
#      xf86-input-synaptics \
#      xorg-xwininfo \
#      menumaker \
#      xfce4-terminal

## Audio: unmute and set volume
pactl -- set-sink-mute 0 0 || die
pactl -- set-sink-volume 0 50% || die

### OPENBOX BASIC CUSTOMIZATION
## create configuration files common to all users:
#    rc.xml, menu.xml, autostart, and environment
mkdir -p ~/.config/openbox \
  && cp -a /etc/xdg/openbox/ ~/.config/ \
    || die

### rc.xml config

#   path: ~/.config/openbox/rc.xml 
#   contents:
#     Key shortcuts, Theming, (Virtual) desktop, Application Window settings
# key shortcuts
bash $HOME/Projects/archlinux/desktop/openbox/shortcuts-openbox.sh \
  || die

### menu.xml:
# path: ~/.config/openbox/menu.xml
# make menu dinamically
mmaker -vf OpenBox3 || die

### autostart: Openbox's own autostart mechanism
# path:
#  runs /etc/xdg/openbox/autostart
#  runs ~/.config/openbox/autostart

# cp $HOME/Projects/archlinux/desktop/openbox/autostart $HOME/.config/openbox
echo '# open custom autostart
bash $HOME/Projects/archlinux/desktop/openbox/autostart &
' > $HOME/.config/openbox/autostart

### environment
# path:
#  sources /etc/xdg/openbox/environment
#  sources ~/.config/openbox/environment
# can be used to export and set relevant environmental variables such as to:
#  Define new pathways (e.g. execute commands that would otherwise require the entire pathway to be listed with them)
#  Change language settings, and
#  Define other variables to be used (e.g. the fix for GTK theming could be listed here)

### Themes
# Openbox-specific and Openbox-compatible themes will be installed to the /usr/share/themes 

## create folders for customization
mkdir -p $HOME/.{themes,icons,wallpapers} || die

## set wallpaper
image="https://i.imgur.com/IwPvX8Z.jpg" || die
my_path=$HOME/.wallpapers/arch-tv-wallpaper.jpg || die
wget --output-document="${my_path}" "${image}" || die
feh --bg-scale -bg-fill $HOME/.wallpapers/arch-tv-wallpaper.jpg || die

### set keyboard layout monitor for X11
url=https://github.com/xkbmon/xkbmon.git
folder="$(basename $url .git)"
[[ ! -d /tmp/$folder ]] && git clone "$url" /tmp/$folder
cd /tmp/$folder || die
make || die
[[ ! -f /usr/local/bin/xkbmon ]] && sudo cp xkbmon /usr/local/bin
cd $OLDPWD || die
### set bar for window manager
if [[ ! -f $HOME/.config/tint2/tint2rc ]]; then
  mkdir -p $HOME/.config/tint2 || die
  cp /etc/xdg/tint2/tint2rc $HOME/.config/tint2 || die
fi
if ! grep Executor $HOME/.config/tint2/tint2rc &> /dev/null; then
  echo '#-------------------------------------
# Executor 1
execp = new
execp_command = xkbmon -u
execp_interval = 1
execp_has_icon = 0
execp_cache_icon = 1
execp_continuous = 1
execp_markup = 0
execp_font = Sans Bold 9
execp_font_color = #dcdcdc 100
execp_padding = 0 0
execp_background_id = 0
execp_centered = 0' >> $HOME/.config/tint2/tint2rc || die
fi
sed -i 's/\(panel_items = \)\(LTSC$\)/\1TSBEC/' $HOME/.config/tint2/tint2rc || die

### set monitor settings
sudo bash -c "echo 'Section \"ServerFlags\"
    Option \"BlankTime\" \"0\"
    Option \"StandbyTime\" \"0\"
    Option \"SuspendTime\" \"0\"
    Option \"OffTime\" \"0\"
    Option \"NoPM\" \"false\"
EndSection

Section \"ServerLayout\"
    Identifier \"ServerLayout0\"
EndSection

Section \"Extensions\"
    Option \"DPMS\" \"Disable\"
EndSection' > /etc/X11/xorg.conf.d/10-monitor.conf"

### conky setup
cd $HOME/Downloads || die
git clone https://aur.archlinux.org/font-symbola.git || die
cd font-symbola || die
makepkg -Ccsri --noconfirm --needed || die
cd $HOME/Projects/archlinux/desktop/openbox \
  && bash conky-install.sh \
    || die

## source variables of the actual linux installation
source $HOME/Projects/archlinux_install_report/installation_report \
  || die

### OPENBOX ADVANCE CUSTOMIZATIONS #########################
case "${MACHINE}" in

## if script is running in VIRTUAL machine:
#   * check if share folder is available
#   * make an autostart shortcut to run a desktop-customization script
  VBox)
    xrandr -s 1920x1080 || die
    msg "screen size set to 2k"
    # https://www.techrepublic.com/article/how-to-create-a-shared-folder-in-virtualbox/
    # sudo mount -t vboxsf shared ~/shared
    
    # if mounted, add shared to fstab & use it in desktop shorcuts
    if ! mount | grep -q shared; then
      echo -e "${user_password}" | sudo -S bash -c "echo \"shared $HOME/shared vboxsf uid=1000,gid=1000 0 0\" >> /etc/fstab"
      ## set permanent startup programs
      sed 's%udiskie &%&\n~/.fehbg \&\nnm-applet \&conky &%' > $HOME/.xinitrc
      ## run customized emacs on startup
 #      cmd="xterm -rv -fa 'Ubuntu Mono' -fs 14  -hold -e"
 #      echo "${cmd} \"bash -c \\\"bash \$HOME/shared/emacs-installer.sh;\
 # exec bash \\\"\" &" >> $HOME/.config/openbox/autostart
    fi
    break
    ;;

## if script is running in REAL machine:
#   * check if share folder is available
#   * make an autostart shortcut to run a desktop-customization script

  Real)
    my_emacs_path="$(lsblk -f | awk '/run.*_EXT/{ print $7 }')" \
      || die
    if [[ -n "${my_emacs_path}" ]]; then
      ## install emacs customized
      bash "${my_emacs_path}"/emacs-installer.sh
      unset my_emacs_path
    else
      mkdir -p $HOME/.emacs.d
      echo ";; init.el -- Emacs init file -*- lexical-binding: t -*-
(load-file \"$HOME/Projects/dot-emacs/init-openbox.el\")
" > $HOME/.emacs.d/init.el
    fi
    break
    ;;
esac

## report time required to install archlinux
duration=$SECONDS
echo "script3_time_seconds=${duration}
total_time_minutes=\"$(((script1_time_seconds + $duration) / 60))\"
" >> $HOME/Projects/archlinux_install_report/installation_report || die

## install emacs
emacs --eval '(save-buffers-kill-terminal)'

