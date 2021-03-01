#!/bin/bash
set -xe

# function to install aur packages

function aur_install {
    folder="$(basename $1 .git)"
    git clone "$1" /tmp/$folder
    cd /tmp/$folder
    makepkg -sri
    cd $OLDPWD
}

## keymap Using "localectl" (RECOMMENDED)
# locatectl --no-convert set-x11-keymap es,us pc105

# localectl set-x11-keymap "es,us" pc105

# add languages to locale
# sudo bash -c "sed -i 's/#es_ES.UTF-8/en_US.UTF-8/g' /etc/locale.gen"
# sudo bash -c "sed -i 's/#de_DE.UTF-8/de_DE.UTF-8/g' /etc/locale.gen"
## ==================== Set Language/keymap ====================

### == Set Language (programmatically, not recommendend) ==

# sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen | locale-gen
# echo 'KEYMAP=es' > /etc/vconsole.conf
# echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# sudo
# bash -c "echo 'Section \"InputClass\"
#      Identifier \"system-keyboard\"
#      MatchIsKeyboard \"on\"
#      Option \"XkbLayout\" \"es,us\"
#      Option \"XkbModel\" \"pc105\"
# EndSection' > /etc/X11/xorg.conf.d/00-keyboard.conf"

# sudo bash -c "echo 'LANG=es_ES.UTF-8
# LC_MESSAGES=en_US.UTF-8' > /etc/locale.conf"

# autologin
# sudo
bash -c "sed -i 's/#autologin-guest=false/autologin-guest=false/g;
             	s/#autologin-user=/autologin-user=$USER/g;
    	     	s/#autologin-user-timeout=0/autologin-user-timeout=0/g'\
		/etc/lightdm/lightdm.conf"

# sudo
groupadd -r autologin

# sudo
gpasswd -a "$USER" autologin

# show grub menu only when shift is pressed 
# sudo
bash -c "echo '
GRUB_FORCE_HIDDEN_MENU=\"true\"
# GRUB menu is hiden until you press \"shift\"' > /etc/default/grub"

# sudo 
wget -c \
 'https://raw.githubusercontent.com/raom2004/arch/master/31_hold_shift' \
 --directory-prefix /etc/grub.d/

# asign permissions to it  

# sudo 
chmod a+x /etc/grub.d/31_hold_shift

# re-generate grub

# sudo 
grub-mkconfig -o /boot/grub/grub.cfg

# fix wrong time in dual boot gnu/linux - windows (linux shell command) 

# timedatectl set-local-rtc 1 --adjust-system-clock

# set custom wallpaper 

# new_user=$(cat /etc/passwd | tail -n1 | awk -F':' ' { print $1 }')

# sudo 
wget -c \
 'https://raw.githubusercontent.com/raom2004/arch/master/bird.jpg' \
 --directory-prefix /home/$user_name/Pictures



# sudo
gsettings set org.cinnamon.desktop.background picture-uri file:////home/$user_name/Pictures/bird.jpg

# # cinnamon sound events

# aur_install https://aur.archlinux.org/mint-artwork-cinnamon.git
# aur_install https://aur.archlinux.org/mint-artwork-common.git

# # firmware modules pending (western digital): aic94xx wd719x xhci_pci
# aur_install https://aur.archlinux.org/aic94xx-firmware.git
# aur_install https://aur.archlinux.org/wd719x-firmware.git
# aur_install https://aur.archlinux.org/upd72020x-fw.git

exit
