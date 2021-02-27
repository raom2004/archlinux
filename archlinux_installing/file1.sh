#!/bin/bash
set -x

localectl set-keymap --no-convert es

timedatectl set-ntp true

parted -s /dev/sda mklabel msdos
parted -s /dev/sda mkpart primary ext4 0% 100%
mkfs.ext4 /dev/sda1
mount /dev/sda1 /mnt

reflector --verbose --latest 2 --sort rate --save /etc/pacman.d/mirrorlist
pacstrap /mnt base linux linux-firmware nano sudo vim git glibc dhcpcd grub

genfstab -L /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

arch-chroot /mnt
