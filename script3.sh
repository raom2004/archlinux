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


## require sudo password for last commands (but do not show it, option -s)
read -sp "[sudo] password for $USER:" user_password


## Audio
pactl -- set-sink-mute 0 0	# turn on audio
pactl -- set-sink-volume 0 50%	# set volume


## Disable saved sessions
xfconf-query --channel xfce4-desktop \
	     --create -p /general/SaveOnExit \
	     --type 'bool' \
	     --set false \
  || die "can not set /general/SaveOnExit $_"


## install theme, icons and wallpaper
# create dot directories
mkdir -p $HOME/.{themes,icons,wallpapers} \
  || die "can not create $_"


## install theme
xfconf-query --channel xsettings \
	     --property /Net/ThemeName \
	     --set Adwaita-dark \
  || die "can not set theme $_"


## install icons
xfconf-query --channel xsettings \
	     --property /Net/IconThemeName \
	     --set Papirus \
  || die "can not ser icon theme $_"


## set a wallpapers to each workspaces
xfconf-query -c xfce4-desktop \
	     --create \
	     -t 'bool' \
	     -p /backdrop/single-workspace-mode \
	     --set false \
  || die "can not set single workspace mode $_"

## set wallpaper in workspace 0 
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


## set wallpaper in workspace 1
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


## set wallpaper in workspace 2 
# download image
image="https://imgur.com/IwPvX8Z" \
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


## set wallpaper in workspace 3 
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

## config xfce panel
# my_bar_position="$(xrandr | awk -F'x' '/*/{ printf $1-8 }' )"
# xfconf-query -c xfce4-panel -p /panels/panel-2/position \
  # 	     --set "p=1;x=${my_bar_position};y=200"
# # bar positioning: --set p=(0:left,1:right);x=#;y=#
xfconf-query -c xfce4-panel -p /panels/panel-2/position-locked \
	     --set true
xfconf-query -c xfce4-panel -p /panels/panel-2/mode \
	     -n -t int \
	     --set 0 		# --set 0:horizontal; 1:vertical
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
	     --set 1 \
  || die "can not set touch mouse pad $_"


## remove desktop icons (value: 0=remove, 2=reinstale)
xfconf-query -c xfce4-desktop -v --create -p /desktop-icons/style \
	     -t int -s 0 \
  || die "can not set desktop icons $_"


## set custom keyboard shortcuts
sh $HOME/Projects/archlinux/desktop/include/shortcuts-xfce.sh \
  || die "can not install $_"


### INSTALL EMACS DEPENDENCIES

## language tools
cd $HOME/Downloads || die "can not cd $_"
url=https://languagetool.org/download/LanguageTool-5.1.zip \
  || die "can not set url $_"
wget "${url}" && extract "$(basename "$_")" \
  || die "can not extract $_"
[[ -d "$(basename "${url}" .zip)" ]] && rm "$(basename "${url}")" \
  || die "can not remove $_"
# ## hunspell english text corrector
# # deprecated: archlinux has a native hunspell-1.7 package, newer
# # hunspell manual installation, version 1.3.2
# # * this zip contain multiple folders, requiring this specific staff
# url=https://sourceforge.net/projects/ezwinports/files/hunspell-1.3.2-3-w32-bin.zip
# wget "${url}" -P $HOME/Downloads/"$(basename "${url}" .zip)" && cd "$_"
# unzip "$(basename "$_")" && rm "$(basename "${url}")"

## emacs org, support for ditaa graphs
url=https://github.com/stathissideris/ditaa/blob/master/service/web/lib/ditaa0_10.jar \
  || die "can not set url $_"
wget "${url}" -P $HOME/Downloads


## delete script after complete xfce desktop setup
# rm -rf $HOME/script3.sh # remove script
rm -rf $HOME/.config/autostart/script3.desktop \ \
  || die "can not remove autostart file $_"


## in virtualbox: share folder and run emacs customized
source $HOME/Projects/archlinux_install_report/installation_report
if [[ "${MACHINE}" == 'VBox' ]]; then
  xrandr -s 1920x1080		# set screen size to 2k
  #https://www.techrepublic.com/article/how-to-create-a-shared-folder-in-virtualbox/
  # sudo mount -t vboxsf shared ~/shared
  if mount | grep -q shared; then
    echo -e "${user_password}" | sudo -S bash -c "echo \"shared $HOME/shared vboxsf uid=1000,gid=1000 0 0\" >> /etc/fstab"
  fi

  ## run customized emacs on startup
  echo '[Desktop Entry]
Type=Application
Name=customized emacs
Comment[C]=run emacs on start up with user customizations
Terminal=false
Exec=xfce4-terminal -e "bash -c \"bash \$HOME/shared/emacs-installer.sh; exec bash\""
X-GNOME-Autostart-enabled=true
NoDisplay=false
' > $HOME/.config/autostart/cemacs.desktop

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

  ## run thunar in specific folder
  echo '[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=thunar startup
Comment=startup filemanager in specific folder
Exec=thunar 
OnlyShowIn=XFCE;
RunHook=0
StartupNotify=false
Terminal=false
Hidden=false' > $HOME/.config/autostart/thunar.desktop
else
  my_emacs_path="$(lsblk -f | awk '/run.*_EXT/{ print $7 }')" \
    || die 'can not set ${my_emacs_path}'
  if [[ -n "${my_emacs_path}" ]]; then
    ## install emacs customized
    bash "${my_emacs_path}"/emacs-installer.sh
  fi
fi


## report time required to install archlinux
duration=$SECONDS
echo "script3_time_seconds=${duration}
total_time_minutes=\"$(((script1_time_seconds + $duration) / 60))\"
" >> $HOME/Projects/archlinux_install_report/installation_report


# sleep 3 && xfce4-session-logout -l
printf "\n\nInstall xfce desktop finished succesfully. Rebooting now!"
sleep 3 && sudo reboot now


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
