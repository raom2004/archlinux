#!/bin/bash
set -x

# * Pre-installing
# ** 1.5 Set the keyboard layout (bash script)

# ; view keyboard settings:
# localectl list-keymaps
# localectl status

# ; set keyboard 
# loadkeys es # temporal
localectl set-keymap --no-convert es

# ** 1.6 Verify the boot mode

# ls /sys/firmware/efi/efivars


# ** 1.7 Connect to the internet

# iwctl
# iwctl --help
# iwctl --passphrase passphrase station device connect SSID


# ** 1.8 Update the system clock (bash script)

timedatectl set-ntp true


# ** 1.9 Partition the disks 

# cfdisk

# ** 1.10 Format the partitions

mkfs.ext2 /dev/sda1 # /boot
mkfs.ext4 /dev/sda2 # /


# ** 1.11 Mount the file systems

mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
mount /dev/sda2 /mnt


# * 2 Installation 


# ** 2.1 Select the mirrors (arch do this automatically)


# ** 2.2 Install essential packages

reflector --verbose --latest 2 --sort rate --save /etc/pacman.d/mirrorlist
pacstrap /mnt base nano


# * 3 Configure the system 


# ** 3.1 Generate an fstab file by UUID (-U) or labels (-L)

genfstab -L /mnt >> /mnt/etc/fstab
# ; check results: 
cat /mnt/etc/fstab


# ** 3.2 Change root (Chroot) into new system

arch-chroot /mnt
