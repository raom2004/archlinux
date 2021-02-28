#!/bin/bash
set -x

# localectl set-keymap --no-convert es

systemctl stop reflector
timedatectl set-ntp true


parted -s /dev/sda \
       mklabel msdos \
       mkpart primary ext2 0% 2% \
       set 1 boot on \
       mkpart primary ext4 2% 100%


mkfs.ext2 /dev/sda1
mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot


reflector --country Germany --country Austria \
	  --verbose --latest 3 --sort rate \
	  --save /etc/pacman.d/mirrorlist


pacstrap /mnt base linux linux-firmware \
	 nano sudo vim git glibc zsh \
	 dhcpcd reflector \
	 grub \
	 xorg-server sddm cinnamon gnome-terminal terminator


genfstab -L /mnt >> /mnt/etc/fstab

cp arch/file2.sh /mnt/home/script2.sh

arch-chroot /mnt sh /home/script2.sh

# rm /mnt/home/script2.sh
# reboot now
x
