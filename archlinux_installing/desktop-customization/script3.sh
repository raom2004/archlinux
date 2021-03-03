#!/bin/bash
set -xe

## Declare Functions
# function to install aur packages
function aur_install {
    folder="$(basename $1 .git)"
    git clone "$1" /tmp/$folder
    cd /tmp/$folder
    makepkg -sri
    cd $OLDPWD
}


## Add keymap Spanish if it is only English (standard)
if $(setxkbmap -query  | awk '/es,us/{ print $0 } ');then
    # Set Keymap Spanish,English "es,us" Using "localectl" (RECOMMENDED)
    localectl set-x11-keymap "es,us" pc105
    # Alternative Way:
    # locatectl --no-convert set-x11-keymap es,us pc105
else
    echo "$(locale -a)"
fi


## enable network manager
systemctl enable NetworkManager


## enable autologin
# set required variables in /etc/lightdm/lightdm.conf
sudo bash -c "sed -i 's/#autologin-guest=false/autologin-guest=false/g;
             	s/#autologin-user=/autologin-user=$USER/g;
    	     	s/#autologin-user-timeout=0/autologin-user-timeout=0/g'\
		/etc/lightdm/lightdm.conf"
# add user to autologin
sudo groupadd -r autologin
sudo gpasswd -a "$USER" autologin


## hide BOOTLOADER menu
# and show it only when shift is pressed 
sudo bash -c "echo '
GRUB_FORCE_HIDDEN_MENU=\"true\"
# GRUB menu is hiden until you press \"shift\"' > /etc/default/grub"
# add script required for this funtionallity
url="https://raw.githubusercontent.com/raom2004/arch/master/desktop-customization/31_hold_shift"
sudo wget $url --directory-prefix=/etc/grub.d/ 
# asign permissions
sudo chmod a+x /etc/grub.d/31_hold_shift
# re-generate BOOTLOADER
sudo grub-mkconfig -o /boot/grub/grub.cfg


## bash customization

sudo pacman -S grml-zsh-config

## TODO: Themes
# Window borders: Arc-Dark
# Icons: Numix-Circle
# Controls: Arc-Dark
# Mouse Pointer: Adwita
# Desktop: Ark-Dark

# install theme requirements
sudo pacman -S adwaita-icon-theme arc-gtk-theme papirus-icon-theme
aur_install https://aur.archlinux.org/packages/numix-circle-icon-theme-git/
aur_install https://aur.archlinux.org/packages/adwaita-custom-cursor-colors.git
aur_install https://aur.archlinux.org/packages/breeze-adapta-cursor-theme-git.git
aur_install https://aur.archlinux.org/sweet-theme-nova-git.git
aur_install https://aur.archlinux.org/bibata-cursor-theme.git
aur_install https://aur.archlinux.org/oxygen-cursors-extra.git
aur_install https://aur.archlinux.org/xcursor-oxygen.git
aur_install https://aur.archlinux.org/oxy-neon.git
aur_install https://aur.archlinux.org/xcursor-arch-cursor-complete.git
aur_install https://aur.archlinux.org/packages/moka-icon-theme-git.git

# font requirements
aur_install https://aur.archlinux.org/ttf-zekton-rg.git

# sounds requirements
# aur_install https://aur.archlinux.org/mint-artwork-cinnamon.git
# aur_install https://aur.archlinux.org/mint-artwork-common.git

## Desktop Customization
gsettings set org.cinnamon.desktop.wm.preferences num-workspaces 4

# cinnamon desktop background
gsettings set org.cinnamon.desktop.background picture-options 'zoom'
gsettings set org.cinnamon.desktop.background picture-uri 'file:///usr/share/backgrounds/gnome/Dark_Ivy.jpg'

# disable screensaver
gsettings set org.cinnamon.desktop.screensaver lock-enabled false

# set interface (window color and fonts)
gsettings set org.cinnamon.desktop.interface gtk-theme 'Arc-Dark'
gsettings set org.cinnamon.desktop.interface font-name 'Zekton 10'
# set nemo font
gsettings set org.nemo.desktop font 'Zekton 10'

# set window manager settings
gsettings set org.cinnamon.desktop.wm.preferences titlebar-font 'Zekton Bold 10'
gsettings set org.cinnamon.desktop.wm.preferences theme 'Arc-Dark'

# gsettings set org.cinnamon.desktop.sound 
sudo pacman -Sy meson sassc --needed --noconfirm
git clone "https://aur.archlinux.org/yaru.git" /tmp/yaru
cd /tmp/yaru
makepkg -sri --noconfirm
sudo mkdir -p /usr/share/sounds/yaru
sudo cp -R -u -p /tmp/yaru/src/yaru-*/sounds/src/* /usr/share/sounds/yaru

## Set Sounds (if yaru package was correctly installed)
if [[ -n $(ls /usr/share/sounds/yaru) ]]; then
    gsettings set org.cinnamon.desktop.sound event-sounds=true
    gsettings set org.cinnamon.desktop.sound volume-sound-file '/usr/share/sounds/yaru/stereo/audio-volume-change.oga'
    gsettings set org.cinnamon.sounds close-enabled true
    gsettings set org.cinnamon.sounds close-file '/usr/share/sounds/yaru/stereo/power-unplug.oga'
    gsettings set org.cinnamon.sounds login-enabled true
    gsettings set org.cinnamon.sounds login-file '/usr/share/sounds/yaru/stereo/system-ready.oga'
    gsettings set org.cinnamon.sounds logout-enabled true
    gsettings set org.cinnamon.sounds logout-file '/usr/share/sounds/yaru/stereo/device-removed.oga'
    gsettings set org.cinnamon.sounds map-enabled true
    gsettings set org.cinnamon.sounds map-file '/usr/share/sounds/yaru/stereo/power-plug.oga'
    gsettings set org.cinnamon.sounds maximize-enabled true
    gsettings set org.cinnamon.sounds maximize-file '/usr/share/sounds/yaru/stereo/power-plug.oga'
    gsettings set org.cinnamon.sounds minimize-enabled true
    gsettings set org.cinnamon.sounds minimize-file '/usr/share/sounds/freedesktop/stereo/window-attention.oga'
    gsettings set org.cinnamon.sounds notification-enabled true
    gsettings set org.cinnamon.sounds notification-file '/usr/share/sounds/yaru/stereo/desktop-login.oga'
    gsettings set org.cinnamon.sounds plug-enabled true
    gsettings set org.cinnamon.sounds plug-file '/usr/share/sounds/yaru/stereo/power-plug.oga'
    gsettings set org.cinnamon.sounds switch-enabled true
    gsettings set org.cinnamon.sounds switch-file '/usr/share/sounds/yaru/stereo/power-plug.oga'
    gsettings set org.cinnamon.sounds unmaximize-enabled true
    gsettings set org.cinnamon.sounds unmaximize-file '/usr/share/sounds/yaru/stereo/device-removed.oga'
    gsettings set org.cinnamon.sounds unplug-enabled true
    gsettings set org.cinnamon.sounds unplug-file '/usr/share/sounds/yaru/stereo/power-unplug.oga'
fi

gsettings set org.cinnamon.settings-daemon.peripherals.touchpad touchpad-enabled true

gsettings set org.cinnamon.theme name 'Arc-Dark'

gsettings set org.gnome.desktop.interface toolkit-accessibility true
gsettings set org.gnome.desktop.interface gtk-im-module 'gtk-im-context-simple'

gsettings set org.gnome.nautilus.preferences default-folder-viewer 'icon-view'
gsettings set org.gnome.nautilus.preferences search-filter-time-type 'last_modified'

# download image from repo
# url="https://github.com/raom2004/arch/blob/master/desktop-customization/bird.jpg?raw=true"
# wget $url --output-document=~/.cinnamon/backgrounds/bird.jpg
# set (cinnamon) desktop background
# gsettings set org.cinnamon.desktop.background picture-uri file:////home/$USER/.cinnamon/backgrounds/bird.jpg

# # firmware modules pending (western digital): aic94xx wd719x xhci_pci
# aur_install https://aur.archlinux.org/aic94xx-firmware.git
# aur_install https://aur.archlinux.org/wd719x-firmware.git
# aur_install https://aur.archlinux.org/upd72020x-fw.git


## update mirrorlist fast before use pacstrap 
# reflector --country Germany --country Austria \
# 	  --verbose --latest 70 --sort rate \
# 	  --save /etc/pacman.d/mirrorlist


exit
