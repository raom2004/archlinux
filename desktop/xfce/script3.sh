#!/bin/bash
#
# ./customizations.sh user customizations for xfce desktop
#
# Dependencies: none
#
### CODE:


### REQUIREMENTS:

# Basic Verifications
if [[ "$EUID" -eq 0 ]]; then	 # user privileges
  echo "Do not run ./$0 as root!"
  exit
elif ! source ~/.functions; then # source dependencies
  echo "can not source ~/.functions" && sleep 3
  exit
elif ! check_internet; then	 # internet connection
  echo "can not run function: check_internet" && sleep 3
  exit
else
  echo "running $0"
  read -p "Allow run script3.sh to customize the desktop?[Y/n]" answer
  [[ "${answer}" == ^([nN])$ ]] && exit
fi    
# measure time
SECONDS=0


### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING ###################


## shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


### ERROR HANDLING

out() { printf "$1 $2\n" "${@:3}"; }
error() { out "==> ERROR:" "$@"; } >&2
warning() { out "==> WARNING:" "$@"; } >&2
msg() { out "==>" "$@"; }
msg2() { out "  ->" "$@";}
die() { error "$@"; exit 1; }


## starting message
echo "Starting basic xfce desktop customization"
## run commands with sudo password (but do not show it, option -s)
read -sp "[sudo] password for $USER:" user_password \
     || die "can not read sudo password"


## backup desktop configuration files before changes  
mkdir -p $HOME/.config_bk || die "can not create $_"
cp -r $HOME/.config/* $HOME/.config_bk || die "can not backup $_"
mkdir -p $HOME/.local_bk || die "can not create $_"
cp -r $HOME/.local/* $HOME/.local_bk || die "can not backup $_"


## Audio
pactl -- set-sink-mute 0 0 || die "can not turn on audio"
pactl -- set-sink-volume 0 50% || die "can not set audio volume $_"


## install theme, icons and wallpaper
# create dot directories
mkdir -p $HOME/.{themes,icons,wallpapers} \
  || die "can not create $_"
# install theme
xfconf-query --channel xsettings \
	     --property /Net/ThemeName \
	     --set Adwaita-dark \
  || die "can not set theme $_"
# install icons
xfconf-query --channel xsettings \
	     --property /Net/IconThemeName \
	     --set Papirus \
  || die "can not ser icon theme $_"
# set a wallpapers to each workspaces
xfconf-query -c xfce4-desktop \
	     --create \
	     -t 'bool' \
	     -p /backdrop/single-workspace-mode \
	     --set false \
  || die "can not set single workspace mode $_"
# set wallpaper in workspace 0 
# download image
image="https://wallpaperforu.com/wp-content/uploads/2020/07/space-wallpaper-200707153544191600x1200.jpg" \
  || die "can not set image $_"
my_path=$HOME/.wallpapers/arch-wallpaper.jpg \
  || die "can not set \$my_path $_" 
wget --output-document="${my_path}" "${image}" \
  || die "can not donwload image $_"
# find path for xfce wallpaper 
image_path="$(xfconf-query -c xfce4-desktop -lv \
			   | awk '/monitor.*last/{ print $1 }' \
			   | sed -n '1p')" \
  || die "can not set \$image_path $_"
# set wallpaper by xfconf-query
xfconf-query -c xfce4-desktop \
	     -p "${image_path}" \
	     -t string \
	     --set "${my_path}" \
  || die "can not set \$image_path \$my_path $_"
# set wallpaper in workspace 1
# download image
image="https://www.setaswall.com/wp-content/uploads/2017/11/Arch-Linux-Wallpaper-28-1920x1080.jpg" \
  || die "can not set image $_"
my_path=$HOME/.wallpapers/space-wallpaper.jpg \
  || die "can not set \$my_path $_"
wget --output-document="${my_path}" "${image}" \
  || die "can not download $_"
# set wallpaper by xfconf-query
image_path="$(xfconf-query -c xfce4-desktop -lv \
			   | awk '/monitor.*last/{ print $1 }' \
			   | sed -n '2p')" \
  || die "can not sel \$image_path $_"
xfconf-query -c xfce4-desktop \
	     -p "${image_path}" \
	     -t string \
	     --set "${my_path}" \
  || die "can not set image $_"
# set wallpaper in workspace 2 
# download image
image="https://i.imgur.com/IwPvX8Z.jpg" \
  || die "can not set \$image $_"
my_path=$HOME/.wallpapers/arch-tv-wallpaper.jpg \
  || die "can not set \$my_path $_"
wget --output-document="${my_path}" "${image}" \
  || die "can not download $_"
# set wallpaper by xfconf-query
image_path="$(xfconf-query -c xfce4-desktop -lv \
			   | awk '/monitor.*last/{ print $1 }' \
			   | sed -n '3p')" \
  || die "can not set \$image_path $_"
xfconf-query -c xfce4-desktop \
	     -p "${image_path}" \
	     -t string \
	     --set "${my_path}" \
  || die "can not set image $_"
# set wallpaper in workspace 3 
# download image
image="https://roboticoverlords.org/wallpapers/feather.png"
my_path=$HOME/.wallpapers/feather-wallpaper.jpg \
  || die "can not set \$my_path $_"
wget --output-document="${my_path}" "${image}" \
  || die "can not download $_"
magick mogrify -negate "${my_path}" \
  || die "can not convert image $_"
# set wallpaper by xfconf-query
image_path="$(xfconf-query -c xfce4-desktop -lv \
	      		   | awk '/monitor.*last/{ print $1 }' \
			   | sed -n '4p')" \
  || die "can not set \$image_path $_"
xfconf-query -c xfce4-desktop \
	     -p "${image_path}" \
	     -t string \
	     --set "${my_path}" \
  || die "can not set $_"

## Sound
# activate sound
xfconf-query -c xsettings -p /Net/EnableEventSounds --set true  \
  || die "can not enable sounds $_"


## config mouse/touchpad
xfconf-query -c pointers -p /ETPS2_Elantech_Touchpad/Properties/libinput_Tapping_Enabled \
	     -n -t int \
	     --set 1 \
  || die "can not set touch mouse pad $_"

## remove desktop icons (value: 0=remove, 2=reinstale)
xfconf-query -c xfce4-desktop -v --create -p /desktop-icons/style \
	     -t int -s 0 \
  || die "can not set desktop icons $_"

## set custom keyboard shortcuts
bash $HOME/Projects/archlinux/desktop/xfce/shortcuts-xfce.sh \
  || die "can not install $_"

## delete script after complete xfce desktop setup
# rm -rf $HOME/script3.sh # remove script
rm -rf $HOME/.config/autostart/script3.desktop \
  || die "can not remove autostart file $_"

# source variables of the actual linux installation
source $HOME/Projects/archlinux_install_report/installation_report \
  || die "can not source $_"
## script running in virtual machine?:
#   * check if share folder is available
#   * make an autostart shortcut to run a desktop-customization script
case "${MACHINE}" in
  VBox)
    xrandr -s 1920x1080 || die "can not set xrandr $_"
    msg "screen size set to 2k"
    # https://www.techrepublic.com/article/how-to-create-a-shared-folder-in-virtualbox/
    # sudo mount -t vboxsf shared ~/shared
    
    # if mounted, add shared to fstab & use it in desktop shorcuts
    if ! mount | grep -q shared; then
      echo -e "${user_password}" | sudo -S bash -c "echo \"shared $HOME/shared vboxsf uid=1000,gid=1000 0 0\" >> /etc/fstab"
      ## run customized emacs on startup
      echo '[Desktop Entry]
Type=Application
Name=script for desktop customization
Comment[C]=desktop customizations
Terminal=false
Exec=xfce4-terminal -e "bash -c \"bash \$HOME/shared/emacs-installer.sh; exec bash\""
X-GNOME-Autostart-enabled=true
NoDisplay=false
' > $HOME/.config/autostart/desktop-customization.desktop
    fi
    break
    ;;
  Real)
    my_emacs_path="$(lsblk -f | awk '/run.*_EXT/{ print $7 }')" \
      || die 'can not set ${my_emacs_path}'
    if [[ -n "${my_emacs_path}" ]]; then
      ## install emacs customized
      bash "${my_emacs_path}"/emacs-installer.sh
      unset my_emacs_path
    fi
    break
    ;;
esac


## report time required to install archlinux
duration=$SECONDS
echo "script3_time_seconds=${duration}
total_time_minutes=\"$(((script1_time_seconds + $duration) / 60))\"
" >> $HOME/Projects/archlinux_install_report/installation_report


## disable prompt on logout
# xfconf-query --channel xfce4-session \
# 	     --create -p /general/PromptOnLogout \
# 	     --type 'bool' \
# 	     --set 'false' \
#   || die "can not set /general/PromptOnLogout $_"

## Disable saved sessions
xfconf-query --channel xfce4-session \
	     --create -p /general/SaveOnExit \
	     --type 'bool' \
	     --set 'false' \
  || die "can not set /general/SaveOnExit $_"
# clear saved xfce session
rm -rf ~/.cache/sessions/*
# clear recently used files
file=$HOME/.local/share/recently-used.xbel
[[ -f "${file}" ]] && rm -rf "${file}"
unset file

# mount shared in fstab require reboot
read -p "$0 succeeded. Reboot required to update fstab. Rebooting now?[Y/n]" response
[[ ! "${response}" =~ ^([nN])$ ]] && sudo reboot now


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
