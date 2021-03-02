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
fi


## autologin
# uncomment required variables
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
sudo  wget -c \
 'https://raw.githubusercontent.com/raom2004/arch/master/31_hold_shift' \
 --directory-prefix /etc/grub.d/
# asign permissions
sudo chmod a+x /etc/grub.d/31_hold_shift
# re-generate BOOTLOADER
sudo grub-mkconfig -o /boot/grub/grub.cfg


## Desktop Customization
# download image from repo
sudo wget -c \
 'https://raw.githubusercontent.com/raom2004/arch/master/bird.jpg' \
 --directory-prefix /home/$USER/Pictures
# set (cinnamon) desktop background
gsettings set org.cinnamon.desktop.background picture-uri file:////home/$USER/Pictures/bird.jpg


## set (cinnamon) desktop sound events
# download sounds
# aur_install https://aur.archlinux.org/mint-artwork-cinnamon.git
# aur_install https://aur.archlinux.org/mint-artwork-common.git


# # firmware modules pending (western digital): aic94xx wd719x xhci_pci
# aur_install https://aur.archlinux.org/aic94xx-firmware.git
# aur_install https://aur.archlinux.org/wd719x-firmware.git
# aur_install https://aur.archlinux.org/upd72020x-fw.git


## update mirrorlist fast before use pacstrap 
# reflector --country Germany --country Austria \
# 	  --verbose --latest 70 --sort rate \
# 	  --save /etc/pacman.d/mirrorlist


exit
