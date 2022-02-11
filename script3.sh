#!/bin/bash
#
# ./script3.sh create user configuration in xfce desktop
#
# Verify user privileges:
if [[ "$EUID" -eq 0 ]]; then echo "./$0 can not be run as root"; exit; fi 
# source dependencies
source ~/.functions
# verify internet connection
check_internet
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


## set a wallpapers to each workspaces
xfconf-query -c xfce4-desktop \
	     --create \
	     -t 'bool' \
	     -p /backdrop/single-workspace-mode \
	     --set false

## set wallpaper in workspace 0 
# download image
image="https://wallpaperforu.com/wp-content/uploads/2020/07/space-wallpaper-200707153544191600x1200.jpg"
my_path=$HOME/.wallpapers/arch-wallpaper.jpg
wget --output-document="${my_path}" "${image}"
# find path for xfce wallpaper 
image_path="$(xfconf-query -c xfce4-desktop -lv \
			   | awk '/monitor.*last/{ print $1 }' \
			   | sed -n '1p')"
# set wallpaper by xfconf-query
xfconf-query -c xfce4-desktop \
	     -p "${image_path}" \
	     -t string \
	     --set "${my_path}"


## set wallpaper in workspace 1
# download image
image="https://www.setaswall.com/wp-content/uploads/2017/11/Arch-Linux-Wallpaper-28-1920x1080.jpg"
my_path=$HOME/.wallpapers/space-wallpaper.jpg
wget --output-document="${my_path}" "${image}"
# set wallpaper by xfconf-query
image_path="$(xfconf-query -c xfce4-desktop -lv \
			   | awk '/monitor.*last/{ print $1 }' \
			   | sed -n '2p')"
xfconf-query -c xfce4-desktop \
	     -p "${image_path}" \
	     -t string \
	     --set "${my_path}"


## set wallpaper in workspace 2 
# download image
image="https://imgur.com/IwPvX8Z"
my_path=$HOME/.wallpapers/arch-tv-wallpaper.jpg
wget --output-document="${my_path}" "${image}"
# set wallpaper by xfconf-query
image_path="$(xfconf-query -c xfce4-desktop -lv \
			   | awk '/monitor.*last/{ print $1 }' \
			   | sed -n '3p')"
xfconf-query -c xfce4-desktop \
	     -p "${image_path}" \
	     -t string \
	     --set "${my_path}"


## set wallpaper in workspace 3 
# download image
image="https://roboticoverlords.org/wallpapers/feather.png"
my_path=$HOME/.wallpapers/feather-wallpaper.jpg
wget --output-document="${my_path}" "${image}"
magick mogrify -negate "${my_path}"
# set wallpaper by xfconf-query
image_path="$(xfconf-query -c xfce4-desktop -lv \
	      		   | awk '/monitor.*last/{ print $1 }' \
			   | sed -n '4p')"
xfconf-query -c xfce4-desktop \
	     -p "${image_path}" \
	     -t string \
	     --set "${my_path}"

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


### INSTALL EMACS DEPENDENCIES

## language tools
cd $HOME/Downloads
url=https://languagetool.org/download/LanguageTool-5.1.zip
wget "${url}" && extract "$(basename "$_")"
[[ -d "$(basename "${url}" .zip)" ]] && rm "$(basename "${url}")"
# ## hunspell english text corrector
# # deprecated: archlinux has a native hunspell-1.7 package, newer
# # hunspell manual installation, version 1.3.2
# # * this zip contain multiple folders, requiring this specific staff
# url=https://sourceforge.net/projects/ezwinports/files/hunspell-1.3.2-3-w32-bin.zip
# wget "${url}" -P $HOME/Downloads/"$(basename "${url}" .zip)" && cd "$_"
# unzip "$(basename "$_")" && rm "$(basename "${url}")"

## emacs org, support for ditaa graphs
url=https://github.com/stathissideris/ditaa/blob/master/service/web/lib/ditaa0_10.jar
wget "${url}" -P $HOME/Downloads


## setup xfce complete: remove script and autostart file
rm -rf $HOME/script3.sh
rm -rf $HOME/.config/autostart/script3.desktop


## in virtualbox: share folder and run emacs customized
source $HOME/Projects/archlinux_install_report/installation_report
if [[ "${MACHINE}" == "VBox" ]]; then
  #https://www.techrepublic.com/article/how-to-create-a-shared-folder-in-virtualbox/
  # sudo mount -t vboxsf shared ~/shared
  sudo bash -c "echo \"shared $HOME/shared vboxsf uid=1000,gid=1000 0 0\" >> /etc/fstab"

  ## run native emacs on startup
  echo "[Desktop Entry]
Type=Application
Name=native emacs
Comment[C]=run emacs on start up with dark theme
Terminal=false
Exec=emacs --eval \"(progn (load-theme 'misterioso)(set-cursor-color \\\"turquoise1\\\"))\"
X-GNOME-Autostart-enabled=true
NoDisplay=false
" > $HOME/.config/autostart/nemacs.desktop
fi

## run customized emacs on startup
  echo "[Desktop Entry]
Type=Application
Name=customized emacs
Comment[C]=run emacs  on start up with user customizations
Terminal=false
Exec=emacs -q -l $HOME/shared/init.el
X-GNOME-Autostart-enabled=true
NoDisplay=false
" > $HOME/.config/autostart/cemacs.desktop
fi

echo '[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=thunar startup
Comment=startup filemanager in specific folder
Exec=thunar $HOME/shared
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false' > $HOME/.config/autostart/thunar.desktop

## report time required to install archlinux
duration=$SECONDS
echo "script3_time_seconds=${duration}
total_time_minutes=\"$(((script1_time_seconds + $duration) / 60))\"
" >> $HOME/Projects/archlinux_install_report/installation_report


# sleep 3 && xfce4-session-logout -l
echo "install finished succesfully. Exiting now!" && sleep 3 && sudo reboot now


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
