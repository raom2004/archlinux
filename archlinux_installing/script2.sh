#!/bin/bash
set -xe

## set timedate 
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

## Set Language
localectl set-locale LANG=en_US.UTF-8

## set host config
# read -p "Enter hostname: " host_name
host_name=example
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

## set root password and add a new user
echo
printf "set root password\n"
(echo "example") | passwd
echo
# read -p "Enter USERNAME: " name
name=$host_name
useradd -m "$name" -s /bin/zsh
# useradd -m $name -s /bin/zsh  # option to define shell
echo
printf "Set $name PASSWORD\n"
passwd "$name"
usermod -aG wheel,audio,optical,storage,power,network "$name"

# usermod -aG wheel,audio,optical,storage,autologin,vboxusers,power,network $name

## enable requited services
# enable wired internet
systemctl enable dhcpcd 
# enable desktop environment at startup
systemctl enable lightdm

# sh /home/script3.sh

exit
