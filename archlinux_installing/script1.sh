#!/bin/bash
#
# script1.h: bash script for install archlinux with support for BIOS/MBR 

## set bash options for: debugging

set -o errexit  # exit if script command fails
set -o nounset  # exit if script try to use undeclared variables
set -o pipefail # catch failed piped commands
set -o xtrace   # trace what gets executed (useful for debugging)


## Check Actual Machine: VIRTUAL vs REAL

pacman -Sy --noconfirm --needed dmidecode
check="$(dmidecode -s system-manufacturer)"
[[ "${check}" == "innotek GmbH" ]] && machine='REAL' || machine='VIRTUAL'


## Check boot: BIOS or UEFI

if ! ls /sys/firmware/efi/efivars;then
  boot_mode="BIOS"
else
  boot_mode="UEFI"
fi

## input variables
case "${#}" in

  0)
    read -p "Enter hostname: " host_name
    read -sp "Enter ROOT password: " root_password
    read -p "Enter NEW user: " user_name
    read -sp "Enter NEW user PASSWORD: " user_password
    ;;
  
  1)
    host_name="Example"
    root_password="Example"
    user_name="Example"
    user_password="Example"
    ;;

  4)
    host_name="${1}"
    root_password="${2}"
    user_name="${3}"
    user_password="${4}"
    ;;

esac

# Ask for target drive to install archlinux
if [[ "${machine}" == 'REAL' ]];then
  lsblk 
  read -t 5 -sp "Enter mountpoint: " mountpoint -i '/dev/sda'
else
  mounpoint="/dev/sda"
fi


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


## install system packages (with desktop env. for virtualization)
pacstrap /mnt base base-devel \
	 mesa \
	 zsh grml-zsh-config nano sudo vim emacs git wget \
	 dhcpcd reflector \
	 grub os-prober \
	 xorg-server lightdm lightdm-gtk-greeter \
	 gnome-terminal terminator cinnamon livecd-sounds


## generate fstab
genfstab -L /mnt >> /mnt/etc/fstab


## copy scripts to new system
cp arch/script2.sh /mnt/home

## change root and run script
arch-chroot /mnt sh /home/script2.sh


## remove script
rm /mnt/home/script2.sh
