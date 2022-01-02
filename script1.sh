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


# BIOS and UEFI support
if ! ls /sys/firmware/efi/efivars >& /dev/null; then
    boot_mode="BIOS"
else
    boot_mode="UEFI"
fi


if [[ ${boot_mode} == "BIOS" ]]; then
    printf "BIOS detected! you can select a GPT or MBR partition table:\n"
    select OPTION in MBR GPT; do
	case ${OPTION} in
	    GPT)
		## HDD partitioning (BIOS/MBR)
		parted -s /dev/sda mklabel msdos
		parted -s -a optimal /dev/sda mkpart primary ext4 0% 100%
		parted -s /dev/sda set 1 boot on
		
		## HDD formating (-F: overwrite if necessary)
		mkfs.ext4 -F /dev/sda1

		## HDD mounting
		mount /dev/sda1 /mnt
		brake
		;;
	    MBR)
		## HDD partitioning (UEFI/GPT)
		parted -s /dev/sda mklabel gpt
		parted -s -a optimal /dev/sda mkpart primary ext2 0% 2MiB
		parted -s /dev/sda set 1 bios_grub on
		parted -s -a optimal /dev/sda mkpart primary ext4 2MiB 100%
		
		## HDD formating (-F: overwrite if necessary)
		mkfs.ext4 -F /dev/sda2
		
		## HDD mounting
		mount /dev/sda2 /mnt
		mkdir -p /mnt/boot
		# mount /dev/sda1 /mnt/boot # mount it just before installing GRUB
		brake
		;;
	esac
    done
fi


if [[ ${boot_mode} == "UEFI" ]]; then
    ## HDD partitioning (UEFI/GPT)
    parted -s /dev/sda mklabel gpt
    parted -s -a optimal /dev/sda mkpart primary ext2 0% 2MiB
    parted -s /dev/sda set 1 esp on
    parted -s -a optimal /dev/sda mkpart primary ext4 2MiB 100%

    ## HDD formating (-F: overwrite if necessary)
    mkfs.fat -F 32 -n ESP /dev/sda2
    mkfs.ext4 -F /dev/sda2

    ## HDD mounting
    mount /dev/sda2 /mnt
    mkdir -p /mnt/boot/efi
    mount /dev/sda1 /mnt/boot/efi
fi


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
