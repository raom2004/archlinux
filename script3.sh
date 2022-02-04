#!/bin/bash
#
# ./script3.sh create user configuration in xfce desktop
#
# Verify user privileges:
if [[ "$EUID" -eq 0 ]]; then echo "./$0 can not be run as root"; exit; fi 
# verify internet connection:
check_internet

### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING ###################


## shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


## Audio
pactl -- set-sink-mute 0 0	# turn on audio
pactl -- set-sink-volume 0 50%	# set volume


## install theme, icons and wallpaper
# create dot directories
mkdir -p $HOME/.{themes,icons,wallpapers}


## install theme
xfconf-query --channel xsettings \
	     --property /Net/ThemeName \
	     --set Adwaita-dark


## install icons
xfconf-query --channel xsettings \
	     --property /Net/IconThemeName \
	     --set Papirus

## set wallpaper

# download image
image="https://wallpaperforu.com/wp-content/uploads/2020/07/space-wallpaper-200707153544191600x1200.jpg"
wget --output-document=$HOME/.wallpapers/space-wallpaper.jpg "${image}"
image="https://www.setaswall.com/wp-content/uploads/2017/11/Arch-Linux-Wallpaper-28-1920x1080.jpg"
wget --output-document=$HOME/.wallpapers/arch-wallpaper.jpg "${image}"
# find path for xfce wallpaper 
image_path="$(xfconf-query -c xfce4-desktop -lv | awk '/monitor.*last/{ print $1 }' | head -n1)"
# set wallpaper in xfce by xfconf-query
xfconf-query -c xfce4-desktop \
	     -p "${image_path}" \
	     -t string \
	     --set $HOME/.wallpapers/arch-wallpaper.jpg

## Sound
# activate sound
xfconf-query -c xsettings -p /Net/EnableEventSounds --set true

## config xfce panel
my_bar_position="$(xrandr | awk -F'x' '/*/{ printf $1-8 }' )"
xfconf-query -c xfce4-panel -p /panels/panel-2/position \
	     --set "p=1;x=${my_bar_position};y=200"
xfconf-query -c xfce4-panel -p /panels/panel-2/position-locked \
	     --set true
xfconf-query -c xfce4-panel -p /panels/panel-2/mode \
	     -n -t int \
	     --set 1
xfconf-query -c xfce4-panel -p /panels/panel-2/enter-opacity \
	     -n -t int \
	     --set 65
xfconf-query -c xfce4-panel -p /panels/panel-2/leave-opacity \
	     -n -t int \
	     --set 65
xfconf-query -c xfce4-panel -p /panels/panel-2/autohide-behavior \
	     --set 2


## config mouse/touchpad
xfconf-query -c pointers -p /ETPS2_Elantech_Touchpad/Properties/libinput_Tapping_Enabled \
	     -n -t int \
	     --set 1


## remove desktop icons (value: 0=remove, 2=reinstale)
xfconf-query -c xfce4-desktop -v --create -p /desktop-icons/style \
	     -t int -s 0


## set custom keyboard shortcuts
# sh "$PWD"/shortcuts-xfce.sh
# sh /usr/bin/shortcuts-xfce.sh


## setup xfce complete: remove script and autostart file
rm -rf $HOME/script3.sh
rm -rf $HOME/.config/autostart/script3.desktop


# echo "install finished succesfully. Exiting now!"
# sleep 3 && xfce4-session-logout -l
sudo reboot now

# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
