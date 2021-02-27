#!/bin/bash
set -x

# localectl set-keymap --no-convert es

# timedatectl set-ntp true

parted -s /dev/sda mklabel msdos
parted -s /dev/sda mkpart primary ext4 0% 100%
mkfs.ext4 /dev/sda1
mount /dev/sda1 /mnt

reflector --verbose --latest 2 --sort rate --save /etc/pacman.d/mirrorlist
pacstrap /mnt base nano git glibc 

#aic94xx #wd719x #xhci_pci
git clone https://aur.archlinux.org/aic94xx-firmware.git
cd aic94xx-firmware
makepkg -sri
cd $PWD

git clone https://aur.archlinux.org/wd719x-firmware.git
cd wd719x-firmware
makepkg -sri
cd $PWD

git clone https://aur.archlinux.org/upd72020x-fw.git
cd upd72020x-fw
makepkg -sri
cd $PWD

# mkinitcpio -p


genfstab -L /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

arch-chroot /mnt
