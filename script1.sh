#!/bin/bash
#
# ./script1.sh is a script to install Arch Linux amd configure a desktop
#
# Summary:
# * This script contain all the commands required to prepare a new system
#   to install Arch Linux.
# * This script also call the script2.sh to execute all the commands
#   that must be run inside the new system, by arch-chroot.


## show what get executed and exit if any command fails
set -xe


## Declare variables to use in script2.sh. Hide passwords by -sp option.
read -p "Enter hostname: " host_name
read -sp "Enter ROOT password: " root_password
read -p "Enter NEW user: " user_name
read -sp "Enter NEW user PASSWORD: " user_password
# make these variables available for script2.sh
export host_name
export root_password
export user_name
export user_password


## set time and synchronize system clock
timedatectl set-ntp true


## HDD partition (BIOS/MBR)
parted -s /dev/sda \
       mklabel msdos \
       mkpart primary ext2 0% 2% \
       set 1 boot on \
       mkpart primary ext4 2% 100%


## HDD formating
mkfs.ext2 /dev/sda1
mkfs.ext4 /dev/sda2


## HDD partitioning mounting
# root partition "/"
mount /dev/sda2 /mnt
# boot partition "/boot"
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot


## install system packages (with support for wifi and ethernet)
pacstrap /mnt base base-devel linux \
	 zsh sudo vim git wget \
	 dhcpcd \
	 networkmanager \
	 grub os-prober \
	 xorg-server lightdm lightdm-gtk-greeter \
	 gnome-terminal terminator cinnamon livecd-sounds \
	 firefox \
	 virtualbox-guest-utils
	 
	 

## generate file system table
genfstab -L /mnt >> /mnt/etc/fstab


## Run comands of script2.sh inside new system with arch-chroot 
# copy script2.sh to new system
cp ./script2.sh /mnt/home
# run script2.sh
arch-chroot /mnt bash /home/script2.sh
# remove script2.sh in the end
rm /mnt/home/script2.sh


## Copy script3.sh with desktop customizations to run on first boot 
cp ./script3.sh /mnt/usr/bin/script3.sh



## In the end unmount everything and exiting
umount -R /mnt
shutdown now
