#!/bin/bash
#
# ./customizations.sh user customizations for openbox desktop
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
  [[ "${answer:-Y}" =~ ^([nN])$ ]] && exit
  unset answer
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
echo "Starting $0 for openbox window manager customization"
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


### OPENBOX AUTOSTART CONFIGURATION

## set background
mkdir -p $HOME/.{themes,icons,wallpapers} \
  || die "can not create $_"
image="https://i.imgur.com/IwPvX8Z.jpg" \
  || die "can not set \$image $_"
my_path=$HOME/.wallpapers/arch-tv-wallpaper.jpg \
  || die "can not set \$my_path $_"
wget --output-document="${my_path}" "${image}" \
  || die "can not download $_"
feh --bg-scale --bg-fill "${my_path}"


### XRESOURCES CONFIGURATION

## install dependencies 

# sudo pacman -S $(pacman -Ssq noto-fonts)

## configure .xresources

echo '! Dracula Xresources palette
*.foreground: #F8F8F2
*.background: #282A36
*.color0:     #000000
*.color8:     #4D4D4D
*.color1:     #FF5555
*.color9:     #FF6E67
*.color2:     #50FA7B
*.color10:    #5AF78E
*.color3:     #F1FA8C
*.color11:    #F4F99D
*.color4:     #BD93F9
*.color12:    #CAA9FA
*.color5:     #FF79C6
*.color13:    #FF92D0
*.color6:     #8BE9FD
*.color14:    #9AEDFE
*.color7:     #BFBFBF
*.color15:    #E6E6E6' > ~/.xresources

## customize xterm font
echo '
XTerm*scrollBar: true
XTerm*scrollbar.width: 8
XTerm*reverseVideo: true
XTerm*geometry: 76x20
XTerm*font: 7x13
XTerm*faceName: Liberation Mono:size=10:antialias=false
XTerm*faceSize: 12
XTerm*faceName: Dejavu Sans Mono:size=10:style=Book:antialias=true
XTerm*cursorColor: cyan
XTerm*cursorBlink: true
' >> ~/.xresources


### OPENBOX CONFIGURATION

## common to all users
mkdir -p ~/.config/openbox
cp -a /etc/xdg/openbox/ ~/.config/

## rc.xml: (pre-configured, only allow add more content)
# path: ~/.config/openbox/rc.xml 
# Key shortcuts, Theming, (Virtual) desktop, Application Window settings
# key shortkut : show menu
echo '
<keybind key="C-m">
    <action name="ShowMenu">
       <menu>root-menu</menu>
    </action>
</keybind>
' >> ~/.config/openbox/rc.xml
# key shortkut : reconfigure  openbox
echo '
<keybind key="W-F11">
  <action name="Reconfigure"/>
</keybind>
 <keybind key="Print">
   <action name="Execute">
     <command>gnome-screenshot -c</command>
   </action>
 </keybind>
 <keybind key="A-Print">
   <action name="Execute">
     <command>gnome-screenshot -c -w</command>
   </action>
 </keybind>
 <keybind key="W-Print">
   <action name="Execute">
     <command>gnome-screenshot -i</command>
   </action>
 </keybind>
' >> ~/.config/openbox/rc.xml
# key shortcuts: window snapping
echo '<keybind key="W-Left">
    <action name="Unmaximize"/>
    <action name="MaximizeVert"/>
    <action name="MoveResizeTo">
        <width>50%</width>
    </action>
    <action name="MoveToEdge"><direction>west</direction></action>
</keybind>
<keybind key="W-Right">
    <action name="Unmaximize"/>
    <action name="MaximizeVert"/>
    <action name="MoveResizeTo">
        <width>50%</width>
    </action>
    <action name="MoveToEdge"><direction>east</direction></action>
</keybind>
' >> ~/.config/openbox/rc.xml
# show icons in menu
echo '
<showIcons>yes</showIcons>
' >> ~/.config/openbox/rc.xml

# echo '<!-- Keybindings for running aplications -->
# <keybind key="my-key-combination">
#   <action name="my-action">
#     ...
#   </action>
# </keybind>
# ' >> ~/.config/openbox/rc.xml

# TODO: download cursor
url=https://aur.archlinux.org/xcursor-human.git
msg "installing AUR package $url"
package_name="$(basename $url .git)"
if ! pacman -Qm "${package_name}"; then
  ## remove directory if previously present in /tmp
  [[ -d /tmp/"${package_name}" ]] && rm -rf /tmp/"${package_name}"
  ## install aur package after check it was not previously installed
  msg "installing AUR package %s\n" "${package_name}"
  git clone "${url}" /tmp/"${package_name}"
  cd /tmp/"${package_name}"
  makepkg -Ccsri --noconfirm --needed
  cd "${OLDPWD}"
else
  warning "AUR package %s is already on system\n" "${package_name}"
  sleep 3
  exit 0
fi
# set cursor
mkdir -p ~/.icons/default
echo '
[icon theme] 
Inherits=xcursor-human
' > ~/.icons/default/index.theme \
     || die "can not set $_"
mkdir -p  ~/.config/gtk-3.0/
echo '
[Settings]
gtk-cursor-theme-name=xcursor-human
' > ~/.config/gtk-3.0/settings.ini \
     || die "can not set $_"

## set wallpaper
# download image
mkdir -p $HOME/.wallpapers \
  || die "can not create $_"
image="https://www.setaswall.com/wp-content/uploads/2017/11/Arch-Linux-Wallpaper-28-1920x1080.jpg" \
  || die "can not set image $_"
my_path=$HOME/.wallpapers/space-wallpaper.jpg \
  || die "can not set \$my_path $_"
wget --output-document="${my_path}" "${image}" \
  || die "can not download $_"
feh --bg-scale $HOME/.wallpapers/space-wallpaper.jpg \
  || die "can not set wallpaper $_"
    

## menu.xml:
# path: ~/.config/openbox/menu.xml
# make menu dinamically
sudo pacman -Syu menumaker --needed --noconfirm
mmaker -vf OpenBox3 || die "menumaker can not create new menus"

## autostart: Openbox's own autostart mechanism:
# path:
#  sources /etc/xdg/openbox/environment
#  sources ~/.config/openbox/environment
#  runs /etc/xdg/openbox/autostart
#  runs ~/.config/openbox/autostart
# Issues regarding commands are often resolved by the addition of small delays
# echo '
# xset -b
# (sleep 3s && nm-applet) &
# (sleep 3s && conky) &
# ' > /etc/xdg/openbox/environment

## set backgroumd permanent
echo '~/.fehbg &
nm-applet & 
conky &' >> $HOME/.xinitrc


## environment
# path: ~/.config/openbox/environment
# can be used to export and set relevant environmental variables such as to:
#  Define new pathways (e.g. execute commands that would otherwise require the entire pathway to be listed with them)
#  Change language settings, and
#  Define other variables to be used (e.g. the fix for GTK theming could be listed here)

## Themes
# Openbox-specific and Openbox-compatible themes will be installed to the /usr/share/themes 

## set custom keyboard shortcuts
bash $HOME/Projects/archlinux/desktop/openbox/shortcuts-openbox.sh \
  || die "can not install $_"

## delete script after complete xfce desktop setup
# rm -rf $HOME/script3.sh # remove script
# rm -rf $HOME/.config/autostart/script3.desktop \
#   || die "can not remove autostart file $_"
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
      echo "xterm -rv -hold -e \"bash -c \\\"bash \$HOME/shared/emacs-installer.sh; exec bash \\\"\" &
" > $HOME/.config/openbox/autostart
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


# mount shared in fstab require reboot
read -p "$0 succeeded. Reboot required to update fstab. Rebooting now?[Y/n]" response
[[ ! "${response}" =~ ^([nN])$ ]] && sudo reboot now


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
