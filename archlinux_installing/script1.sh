#!/bin/bash

set -xe

# loadkeys es


## stop reflector.service 
# systemctl stop reflector


## input variables
read -p 'Enter hostname: ' host_name
read -s 'Enter ROOT password: ' root_password
read -p 'Enter NEW user: ' user_name
read -s 'Enter NEW user PASSWORD: ' user_password
# make variables available for subsecuent scripts
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
# partition "/"
mount /dev/sda2 /mnt
# partition "/boot"
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot


## install minimun system packages (no desktop environment)
# pacstrap /mnt --needed base base-devel linux \
# 	 nano sudo zsh \
# 	 dhcpcd \
# 	 grub

## install system packages (with desktop environment)
# pacstrap /mnt base base-devel linux linux-firmware \
# 	 zsh nano sudo vim emacs git glibc wget \
# 	 dhcpcd reflector \
# 	 grub os-prober \
# 	 xorg-server lightdm lightdm-gtk-greeter \
# 	 gnome-terminal terminator cinnamon
	 
## install system packages (with desktop env. for virtualization)
pacstrap /mnt base base-devel \
	 virtualbox-guest-utils \
	 xf86-video-intel \
	 zsh nano sudo vim emacs git glibc wget \
	 dhcpcd reflector \
	 grub os-prober \
	 xorg-server lightdm lightdm-gtk-greeter \
	 gnome-terminal terminator cinnamon \
	 gnome-keyring lisecret seahorse
	 

## generate fstab
genfstab -L /mnt >> /mnt/etc/fstab


## copy script to new system
cp arch/script2.sh /mnt/home


## change root and run script
arch-chroot /mnt sh /home/script2.sh


## remove script
rm /mnt/home/script2.sh


## shutdown the system if no errors stops the script (option "set -xe")
shutdown now
