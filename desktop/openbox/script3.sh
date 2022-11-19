#!/bin/bash
#
# ./customizations.sh user customizations for openbox desktop
#
# Dependencies: none
#
### CODE:

############################################################
### CODE HEADER ############################################
############################################################


## BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING

# shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)



### DECLARE FUNCTIONS


########################################
# Purpose: ERROR HANDLING FUNCTIONS
# Requirements: None
########################################
## Deprecated
# out() { printf "$1 $2\n" "${@:3}"; }
# error() { out "==> ERROR:" "$@"; } >&2
# warning() { out "==> WARNING:" "$@"; } >&2
# msg() { out "==>" "$@"; }
# msg2() { out "  ->" "$@";}
# die() { error "$@"; exit 1; }

## ERROR HANDLING
function out     { printf "$1 $2\n" "${@:3}"; }
# function error   { out "==> ERROR:" "$@"; } >&2
# function die     { error "$@"; exit 1; }
function die {
  # if error, exit and show file of origin, line number and function
  # colors
  NO_FORMAT="\033[0m"
  C_RED="\033[38;5;9m"
  C_YEL="\033[38;5;226m"
  # color functions
  function msg_red { printf "${C_RED}${@}${NO_FORMAT}"; }
  function msg_yel { printf "${C_YEL}${@}${NO_FORMAT}"; }
  # error detailed message (colored)
  msg_red "==> ERROR: " && printf " %s" "$@" && printf "\n"
  msg_yel "  -> file: " && printf "${BASH_SOURCE[1]}\n"
  msg_yel "  -> func: " && printf "${FUNCNAME[2]}\n"
  msg_yel "  -> line: " && printf "${BASH_LINENO[1]}\n"
  exit 1
}

## MESSAGES
function warning { out "==> WARNING:" "$@"; } >&2
function msg     { out "==>" "$@"; }
function msg2    { out "  ->" "$@"; }

############################################################
### MAIN CODE ##############################################
############################################################


## Basic Verifications

if [[ "$EUID" -eq 0 ]]; then	 # user privileges
  echo "Do not run ./$0 as root!"
  exit
else
  echo "Wellcome to OPENBOX customization:"
  read -p "==> Start $0 to customize the new desktop?[Y/n]" answer
  [[ "${answer:-Y}" =~ ^([nN])$ ]] && exit
  unset answer
  echo "--> Starting $0 to cutomize OPENBOX window manager"
fi    

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

sudo pacman -Syu --needed --noconfirm \
     xf86-input-synaptics \
     xorg-xwininfo \
     menumaker

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

cp $HOME/Projects/archlinux/desktop/openbox/autostart $HOME/.config/openbox


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


############################################################
### CODE FOOTER ############################################
############################################################


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
      cmd="xterm -rv -fa 'Ubuntu Mono' -fs 14  -hold -e"
      echo "${cmd} \"bash -c \\\"bash \$HOME/shared/emacs-installer.sh;\
 exec bash \\\"\" &" >> $HOME/.config/openbox/autostart
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
    fi
    break
    ;;
esac


## report time required to install archlinux
duration=$SECONDS
echo "script3_time_seconds=${duration}
total_time_minutes=\"$(((script1_time_seconds + $duration) / 60))\"
" >> $HOME/Projects/archlinux_install_report/installation_report || die


# mount shared in fstab require reboot
read -p "$0 succeeded. Reboot required to update fstab. Rebooting now?[Y/n]" response
[[ ! "${response}" =~ ^([nN])$ ]] && sudo reboot now


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
