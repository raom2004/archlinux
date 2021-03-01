#!/bin/bash
set -x

# function to install aur packages

function aur_install {
    folder="$(basename $1 .git)"
    git clone "$1" /tmp/$folder
    cd /tmp/$folder
    makepkg -sri
    cd $OLDPWD
}

# add languages to locale
# sudo bash -c "sed -i 's/#es_ES.UTF-8/en_US.UTF-8/g' /etc/locale.gen"
# sudo bash -c "sed -i 's/#de_DE.UTF-8/de_DE.UTF-8/g' /etc/locale.gen"
## ==================== Set Language/keymap ====================

### == Set Language (programmatically, not recommendend) ==

# sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen | locale-gen
# echo 'KEYMAP=es' > /etc/vconsole.conf
# echo 'LANG=en_US.UTF-8' > /etc/locale.conf
# echo 'Section "InputClass"
#      Identifier "system-keyboard"
#      MatchIsKeyboard "on"
#      Option "XkbLayout" "es,us"
#      Option "XkbModel" "pc105"
# EndSection' > /etc/X11/xorg.conf.d/00-keyboard.conf

# sudo bash -c "echo 'LANG=es_ES.UTF-8
# LC_MESSAGES=en_US.UTF-8' > /etc/locale.conf"

# autologin
sudo bash -c "sed -i 's/#autologin-guest=false/autologin-guest=false/g;
             	s/#autologin-user=/autologin-user=$USER/g;
    	     	s/#autologin-user-timeout=0/autologin-user-timeout=0/g'\
		/etc/lightdm/lightdm.conf"

sudo groupadd -r autologin

sudo gpasswd -a "$USER" autologin

# show grub menu only when shift is pressed 
sudo bash -c "echo '
GRUB_FORCE_HIDDEN_MENU=\"true\"
# GRUB menu is hiden until you press \"shift\"' > /etc/default/grub"

sudo wget -c \
 'https://raw.githubusercontent.com/raom2004/arch/master/31_hold_shift' \
 --directory-prefix /etc/grub.d/

# asign permissions to it  

sudo chmod a+x /etc/grub.d/31_hold_shift

# re-generate grub

sudo grub-mkconfig -o /boot/grub/grub.cfg

# fix wrong time in dual boot gnu/linux - windows (linux shell command) 

# timedatectl set-local-rtc 1 --adjust-system-clock

# set custom wallpaper 

wget -c \
 'https://raw.githubusercontent.com/raom2004/arch/master/bird.jpg' \
 --directory-prefix /home/$USER/Pictures

gsettings set org.cinnamon.desktop.background picture-uri file:////home/$USER/Pictures/bird.jpg

# # cinnamon sound events

# aur_install https://aur.archlinux.org/mint-artwork-cinnamon.git
# aur_install https://aur.archlinux.org/mint-artwork-common.git

# # firmware modules pending (western digital): aic94xx wd719x xhci_pci
# aur_install https://aur.archlinux.org/aic94xx-firmware.git
# aur_install https://aur.archlinux.org/wd719x-firmware.git
# aur_install https://aur.archlinux.org/upd72020x-fw.git

## set key combinations
# sudo setxkbmap -option compose:alt_ctrl
## set key combinations (and layouts)
sudo localectl set-x11-keymap "es,us" pc105 "" \
     grp:lalt_lctrl_caps_toogle,compose:rwin-altgr
# file=~/.XCompose
# cat << EOF > "$file"
# include "%L"
# <Multi_key> <g> <a> : "α"
# <Multi_key> <g> <b> : "β"
# <Multi_key> <g> <g> : "γ"
# <Multi_key> <g> <d> : "δ"
# <Multi_key> <g> <e> : "ε"
# <Multi_key> <g> <z> : "ζ"
# <Multi_key> <g> <n> : "η"
# <Multi_key> <g> <t> : "θ"
# <Multi_key> <g> <i> : "ι"
# <Multi_key> <g> <k> : "κ"
# <Multi_key> <g> <l> : "λ"
# <Multi_key> <g> <m> : "μ"
# <Multi_key> <g> <v> : "ν"
# <Multi_key> <g> <x> <i> : "ξ"
# <Multi_key> <g> <p> <i> : "π"
# <Multi_key> <g> <r> <o> : "ρ"
# <Multi_key> <g> <s> : "σ"
# <Multi_key> <g> <t> : "τ"
# <Multi_key> <g> <u> : "υ"
# <Multi_key> <g> <f> : "φ"
# <Multi_key> <g> <j> <i> : "χ"
# <Multi_key> <g> <p> <s> <i> : "ψ"
# <Multi_key> <g> <o> : "ω"
# <Multi_key> <g> <l> <i> : "🔗"
# EOF
