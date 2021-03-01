#!/bin/bash
set -xe


## Time Configuration 
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc


## Language Configuration
localectl set-locale LANG=en_US.UTF-8


## Network Configuration
# read -p "Enter hostname: " host_name
echo "$host_name" > /etc/hostname
bash -c "echo '127.0.0.1	localhost
::1		localhost
127.0.1.1	${host_name}.localdomain	$host_name' >> /etc/hosts"


## TODO: firmware modules pending: aic94xx wd719x xhci_pci

## bash script to handle encrypted root filesystems 
# mkinitcpio -p 


## install and config a bootloader
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg


## turn on "wheel" groups, required by sudo (use sed instead visudo)
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers


## Accounts Config
# set root password
echo -e "$root_password\n$root_password" | (passwd root)
# create new user
# useradd -m "$user_name" -s /bin/zsh
useradd -m "$user_name"
# set new user password
echo -e "$user_password\n$user_password" | (passwd $user_name)
# set user groups
usermod -aG wheel,audio,optical,storage,power,network "$user_name"
# usermod -aG wheel,audio,optical,storage,autologin,vboxusers,power,network $name


## enable requited services
# run DHPCv6 client for network configuration
systemctl enable dhcpcd 
# enable desktop environment at startup
systemctl enable lightdm

# sh /home/script3.sh
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
# sudo 
wget -c \
 'https://raw.githubusercontent.com/raom2004/arch/master/bird.jpg' \
 --directory-prefix /home/$USER/Pictures



# sudo
gsettings set org.cinnamon.desktop.background picture-uri file:////home/$USER/Pictures/bird.jpg
exit
