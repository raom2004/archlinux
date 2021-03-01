#!/bin/bash
set -xe

## set timedate 
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

## Set Language
localectl set-locale LANG=en_US.UTF-8

## set host config
# read -p "Enter hostname: " host_name
echo "$host_name" > /etc/hostname
bash -c "echo '127.0.0.1	localhost
::1		localhost
127.0.1.1	${host_name}.localdomain	$host_name' >> /etc/hosts"


## TODO: firmware modules pending: aic94xx wd719x xhci_pci

## optional
# mkinitcpio -p 


## install bootloader and config it
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

## turn on wheel, required by sudo 
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
# visudo

## Accounts Config
# set root password
echo -e "$root_password\$root_password" | (passwd root)
# create new user
useradd -m "$user_name" -s /bin/zsh
# set new user password
echo -e "$user_password\$user_password" | (passwd $user_name)
# set user groups
usermod -aG wheel,audio,optical,storage,power,network "$user_name"

# usermod -aG wheel,audio,optical,storage,autologin,vboxusers,power,network $name

## enable requited services
# enable wired internet
systemctl enable dhcpcd 
# enable desktop environment at startup
systemctl enable lightdm

# sh /home/script3.sh

exit
