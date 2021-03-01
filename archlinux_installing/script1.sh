#!/bin/bash
set -xe

## stop reflector.service 
# systemctl stop reflector

## set keymap (temporal)
# localectl set-keymap --no-convert es


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
reflector --country Germany --country Austria \
	  --verbose --latest 3 --sort rate \
	  --save /etc/pacman.d/mirrorlist


pacstrap /mnt base linux \
	 virtualbox-guest-utils \
	 xf86-video-intel \
	 nano sudo vim emacs git glibc wget zsh \
	 dhcpcd reflector \
	 grub os-prober \
	 xorg-server lightdm lightdm-gtk-greeter \
	 cinnamon \
	 gnome-terminal
	 

## generate fstab
genfstab -L /mnt >> /mnt/etc/fstab


## copy script to new system
cp arch/script*.sh /mnt/home

## change root and run script
arch-chroot /mnt sh /home/script2.sh

## remove script
rm /mnt/home/script*.sh

## shutdown system at end
shutdown now
