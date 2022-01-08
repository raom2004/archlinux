#!/bin/bash
#
# ./script3.sh is a script to setup an Arch Linux desktop on first boot
#
# Summary:
# * This script contain all the customization of a new desktop.
# * It run on first boot thanks to a script3.dektop file in autostart
# * In the end this script will remove the script3.desktop file so
#   it can only be run once


## show all the command that get executed and exit if anything fails
set -xe


# install aur packages without confirmation
function aur_install {
    folder="$(basename $1 .git)"
    if [[ ! -n "$(pacman -Qm ${folder})" ]]; then 
	echo "installing AUR package ${folder}"
	git clone "$1" "/tmp/${folder}"
	cd "/tmp/${folder}"
	makepkg -sri --noconfirm
	cd $OLDPWD
    fi
    unset -v folder
}


## ADD USER STANDARD DIRECTORIES
sudo pacman -S --needed xdg-user-dirs  --noconfirm
LC_ALL=C xdg-user-dirs-update --force


## ADD ADDITIONAL KEYMAP LAYOUT (e.g. Spanish)
if [[ -z "$(setxkbmap -query  | awk '/us,|,us/{ print $0 } ')" ]]; then
  localectl set-x11-keymap "es,us" pc105
fi


## ENABLE AUTOLOGIN
if [ -n "$(grep '#autologin-guest=false' /etc/lightdm/lightdm.conf)" ];then
    sudo bash -c "sed -i 's/\(#\)autologin-guest=false/\1/g;
             	s/\(#\)autologin-user=/\1$USER/g;
    	     	s/\(#\)autologin-user-timeout=0/\1/g'\
		/etc/lightdm/lightdm.conf"
    # add user to autologin
    sudo groupadd -r autologin
    sudo gpasswd -a "$USER" autologin
fi


## HIDE BOOTLOADER MENU AT STARTUP (and show it pressing SHIFT key)
if [ ! -n "$(grep GRUB_FORCE_HIDDEN_MENU /etc/default/grub)" ]; then
    sudo bash -c "echo '
GRUB_FORCE_HIDDEN_MENU=\"true\"
    # GRUB menu is hiden until you press \"shift\"' > /etc/default/grub"
    # add script required for this funtionallity
    url="https://gist.githubusercontent.com/anonymous/8eb2019db2e278ba99be/raw/257f15100fd46aeeb8e33a7629b209d0a14b9975/gistfile1.sh"
    sudo wget "${url}" -O /etc/grub.d/31_hold_shift
    # asign permissions & re-generate bootloader
    sudo chmod a+x /etc/grub.d/31_hold_shift
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi


## THEME CUSTOMIZATION
sudo pacman -S --needed arc-gtk-theme \
     papirus-icon-theme --noconfirm
# arch cursor
aur_install https://aur.archlinux.org/xcursor-arch-cursor-complete.git
# desktop font 
aur_install https://aur.archlinux.org/ttf-zekton-rg.git


## SYMBOL SUPPORT FONT
aur_install https://aur.archlinux.org/font-symbola.git


## DESKTOP CUSTOMIZATION
gsettings set org.cinnamon.desktop.wm.preferences num-workspaces 4
# cinnamon desktop background
gsettings set org.cinnamon.desktop.background picture-options 'zoom'
gsettings set org.cinnamon.desktop.background picture-uri 'file:///usr/share/backgrounds/gnome/LightWaves.jpg'
# disable screensaver
gsettings set org.cinnamon.desktop.screensaver lock-enabled false
# set window interface color and fonts
gsettings set org.cinnamon.desktop.interface icon-theme 'ePapirus'
gsettings set org.cinnamon.desktop.interface gtk-theme 'Arc-Dark'
gsettings set org.cinnamon.desktop.interface font-name 'Zekton 10'
gsettings set org.cinnamon.desktop.interface cursor-theme 'ArchCursorComplete'
# set nemo font
gsettings set org.nemo.desktop font 'Zekton 10'
# set window manager settings
gsettings set org.cinnamon.desktop.wm.preferences titlebar-font 'Zekton Bold 10'
gsettings set org.cinnamon.desktop.wm.preferences theme 'Arc-Dark'
gsettings set org.cinnamon.settings-daemon.peripherals.touchpad touchpad-enabled true
gsettings set org.cinnamon.theme name 'Arc-Dark'
gsettings set org.gnome.desktop.interface toolkit-accessibility true
gsettings set org.gnome.desktop.interface gtk-im-module 'gtk-im-context-simple'


## SHELL CUSTOMIZATION
sudo pacman -S --needed --noconfirm \
     neofetch \
     ttf-nerd-fonts-symbols-mono \
     ttf-dejavu

# Pacman 
sudo sed -i 's/\(#\)Color/\1/' /etc/pacman.conf

# Bash
sudo pacman -S --needed --noconfirm bash-completion
url="https://raw.githubusercontent.com/raom2004/archlinux/part/02_archlinux_dotfiles/.bashrc"
wget "$url" --output-document=/$HOME/.bashrc

# Bash prompt
url="https://raw.githubusercontent.com/raom2004/archlinux/part/02_archlinux_dotfiles/.bash_prompt"
wget "$url" --output-document=/$HOME/.bash_prompt

# Zsh
[[ -f "/$HOME/.zshrc" ]] && sudo mv /$HOME/.zshrc /$HOME/.zshrc_backup
url="https://raw.githubusercontent.com/raom2004/archlinux/part/02_archlinux_dotfiles/.zshrc"
wget "$url" --output-document=/$HOME/.zshrc
unset -v url

## CONFIGURE SOUND
sudo pacman -S --needed --noconfirm \
     pulsemixer \
     sound-theme-freedesktop \
     deepin-sound-theme

# Set Sounds (require deepin sounds package)
if [[ -n "$(ls /usr/share/sounds/deepin)" ]]; then
    gsettings set org.cinnamon.desktop.sound event-sounds true
    gsettings set org.cinnamon.desktop.sound volume-sound-file '/usr/share/sounds/deepin/stereo/audio-volume-change.wav'
    gsettings set org.cinnamon.sounds close-enabled true
    gsettings set org.cinnamon.sounds close-file '/usr/share/sounds/deepin/stereo/desktop-login.wav'
    gsettings set org.cinnamon.sounds login-enabled true
    gsettings set org.cinnamon.sounds login-file '/usr/share/sounds/deepin/stereo/desktop-logout.wav'
    gsettings set org.cinnamon.sounds logout-enabled true
    gsettings set org.cinnamon.sounds logout-file '/usr/share/sounds/deepin/stereo/device-removed.wav'
    gsettings set org.cinnamon.sounds map-enabled true
    gsettings set org.cinnamon.sounds map-file '/usr/share/sounds/deepin/stereo/power-plug.wav'
    gsettings set org.cinnamon.sounds maximize-enabled true
    gsettings set org.cinnamon.sounds maximize-file '/usr/share/sounds/deepin/stereo/power-plug.wav'
    gsettings set org.cinnamon.sounds minimize-enabled true
    gsettings set org.cinnamon.sounds minimize-file '/usr/share/sounds/freedesktop/stereo/window-attention.wav'
    gsettings set org.cinnamon.sounds notification-enabled true
    gsettings set org.cinnamon.sounds notification-file '/usr/share/sounds/deepin/stereo/desktop-login.wav'
    gsettings set org.cinnamon.sounds plug-enabled true
    gsettings set org.cinnamon.sounds plug-file '/usr/share/sounds/deepin/stereo/power-plug.wav'
    gsettings set org.cinnamon.sounds switch-enabled true
    gsettings set org.cinnamon.sounds switch-file '/usr/share/sounds/deepin/stereo/power-plug.wav'
    gsettings set org.cinnamon.sounds unmaximize-enabled true
    gsettings set org.cinnamon.sounds unmaximize-file '/usr/share/sounds/deepin/stereo/device-removed.wav'
    gsettings set org.cinnamon.sounds unplug-enabled true
    gsettings set org.cinnamon.sounds unplug-file '/usr/share/sounds/deepin/stereo/power-unplug.wav'
fi


## turn on audio (because its off by default)
pactl set-sink-mute 0 0
pactl -- set-sink-volume 0 50%


## systemctl disable script3.service
sudo rm -rf /etc/xdg/autostart/script3.desktop


# restart
sudo reboot now
