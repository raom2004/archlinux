#!/bin/bash
set -x

localectl set-keymap --no-convert es

timedatectl set-ntp true

parted /dev/sda mklabel msdos
parted /dev/sda mkpart primary ext4 0% 100%

mount /dev/sda1 /mnt

# reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
# pacstrap /mnt base nano git glibc 

# genfstab -L /mnt >> /mnt/etc/fstab
# cat /mnt/etc/fstab

# arch-chroot /mnt
