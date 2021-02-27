#!/bin/bash
set -x

# localectl set-keymap --no-convert es

# timedatectl set-ntp true

parted -s /dev/sda mklabel msdos
mkfs.ext4 /dev/sda1
mount /dev/sda1 /mnt

reflector --verbose --latest 2 --sort rate --save /etc/pacman.d/mirrorlist
pacstrap /mnt base nano git glibc 

genfstab -L /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

arch-chroot /mnt
