#!/bin/bash
set -xe

# loadkeys es

## stop reflector.service 
# systemctl stop reflector

## input variables
read -p "Enter hostname: " host_name
read -p "Enter ROOT password: " root_password
read -p "Enter NEW user: " user_name
read -p "Enter NEW user PASSWORD: " user_password
export host_name
export root_password
export user_name
export user_password


## set time and synchronize system clock
timedatectl set-ntp true


## partition hdd
parted -s /dev/sda \
       mklabel msdos \
       mkpart primary ext2 0% 2% \
       set 1 boot on \
       mkpart primary ext4 2% 100%


## formating hdd
mkfs.ext2 /dev/sda1
mkfs.ext4 /dev/sda2


## mount new partitions
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot


## update mirrorlist fast before use pacstrap 
# reflector --country Germany --country Austria \
# 	  --verbose --latest 3 --sort rate \
# 	  --save /etc/pacman.d/mirrorlist

# pacstrap /mnt --needed base linux \
# 	 nano sudo zsh \
# 	 dhcpcd \
# 	 grub

# pacstrap /mnt base linux \
# 	 virtualbox-guest-utils \
# 	 xf86-video-intel \
# 	 zsh nano sudo vim emacs git glibc wget \
# 	 dhcpcd reflector \
# 	 grub os-prober \
# 	 xorg-server lightdm lightdm-gtk-greeter \
# 	 gnome-terminal terminator cinnamon
	 
pacstrap /mnt base linux \
	 bash zsh nano sudo vim emacs git glibc wget \
	 dhcpcd reflector \
	 grub os-prober \
	 xorg-server lightdm lightdm-gtk-greeter \
	 gnome-terminal terminator cinnamon
	 

## generate fstab
genfstab -L /mnt >> /mnt/etc/fstab


## copy script to new system
cp arch/script*.sh /mnt/home

## change root and run script
arch-chroot /mnt sh /home/script2.sh

## remove script
# rm /mnt/home/script*.sh

## shutdown system at end
shutdown now
