#!/bin/bash
#
# script1.h: bash script for install archlinux with support for BIOS/MBR 

# Dependencies:
#  built-in files (see above)

## Continue only if internet connection is available
if ! ping -c 1 -q google.com >&/dev/null; then
  echo "Internet not available"
  exit 0
fi

### BASH OPTIONS FOR SECURITY AND DEBUGGING
# shopt -o noclobber # prevent file overwriting (>) but can forced by (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)

### DEPENDENCIES
source ./include/ANSI_escape_colors
source ./include/functions


### VARIABLE DECLARATION
installer_version=v0.8.0
script_start_time="$(date +%s)"


### FUNCTION DECLARATION


########################################
# Purpose: display usage of this archlinux installer bash script 
# Arguments: global variable "installer_version"
########################################

function display_usage
{
  printf "
ARCHLINUX installer Version %s
Summary: 
  A bash script that automates the archlinux install. It follows the
  official guidelines, including install and boot archlinux from
  internal HDD and removable devices, such as: USB, SD or MMC.

Usage: ${0##*/} [options]
  -h|--help         display usage

Example:
  ${Green}$ sh ${0}${NC} 

The archlinux install will ask for the variables, on demand:
  * A block device for install linux on, e.g. \"/dev/sdX\"
  * A name for the host
  * A root password
  * A new user name
  * A password for the new user
  * A shell for the user, options: \"bash\", \"zsh\"

The archlinux installer include other advanced options, such as:
  * Activate automatic logging on tty1 (only for testing purposes).
  * Create a duplicate of the system, with dd, for recovery and testing.

Why include an option to duplicate the system?
  Well, archlinux maintenance require packages and kernel upgrades
  that could break the system. For this reason, have a booteable
  duplicate of the system its advantageus to test upgrades before
  apply them in the main system, or easily recover the system after an
  important failure.

How this installer will partition the disk?
In the standard install, without recovery, the disk partitioning will be:
  * A /boot partition, dedicated for the bootloader (GRUB). 
  * A /root partition, for the archlinux system.

When you choose to have a recovery partition, this installer will create: 
  * A /root partition containing the original archlinux system.
  * A /root duplicate, booteable for upgrade testing or recovery.
  * A /boot partition, to store the boot files for both systems.
  * A /home partition, to make documents available for both systems.

" "${installer_version}"
  exit 0
}


########################################
# Purpose: dialog to select a target block device for archlinux install
# Arguments: $1
# Return: the argument $1 will store a valid block device (e.g. /dev/sdX)
########################################

function dialog_to_input_a_target_device
{
  # The functions result will be stored in the variable "__resultvar".
  local __resultvar="${1}"
  # Help the user showing the block devices available
  local array_of_block_devices=($(lsblk | awk '/disk/{ print $1 }'))
  printf "List of block devices (lsblk):\n%s\n\n" "$(lsblk)"
  printf "Between the block devices detailed bellow,\n"
  printf "choose a device to install archlinux on:\n"
  # The function help the user to choose and return a block device.
  select option in "${array_of_block_devices[@]}";do
    case "${option}" in
      "")
	printf "\nInvalid option. Canceling install!\n\n"; exit 0 ;;
      *)
	# The function can't set a variable directly, but EVAL can:
	eval "${__resultvar}"="/dev/${option}"; break ;;
    esac
  done
}


######################################################################
### MAIN CODE ########################################################
######################################################################


### HELP

# display usage when user provide the help tag '--help | -h' 
[[ "${#}" == 1 ]] && [[ "${1}" =~ (--help)|(-h) ]] && display_usage


### GET SYSTEM INFORMATION

# Get Current Machine: Virtualbox (VBox) vs REAL
pacman -Sy --noconfirm --needed dmidecode
check="$(dmidecode -s system-manufacturer)"
[[ "${check}" == "innotek GmbH" ]] && machine='VBox' || machine='REAL'

# Get Current Boot Mode:
if ! ls /sys/firmware/efi/efivars 2>/dev/null;then
  boot_mode='BIOS'
else
  boot_mode='UEFI'
fi


### GET PARAMETERS REQUIRED FOR ARCHLINUX INSTALL

printf "${Green}The archlinux install required some parameters:${NC}"

# dialog to choose a target device (/dev/sdX) to install linux on
[[ "${machine}" == 'REAL' ]] \
  && dialog_to_input_a_target_device target_device

# in VirtualBox machine please set target device without dialog
[[ "${machine}" == 'VBox' ]] && target_device=/dev/sda

# log parameters, for security passwords are hidden (read -s)
read -p "Enter HOST name: " host_name
read -sp "Enter ROOT PASSWORD: " root_password
read -p "Enter USER name: " user_name
read -sp "Enter USER PASSWORD: " user_password

# parameters with fixed options that need to be validated
read -p "Enter USER SHELL (e.g. bash, zsh) " user_shell
[[ ! "${user_shell}" =~ ^([b][a]|[z])(sh)$ ]] && echo "invalid"; exit 1
read -p "Do you want autolog tty at startup?[y/N]" autolog_tty
[[ ! "${autolog_tty}" =~ ^([yY]|[nN])$ ]] && echo "invalid"; exit 1

# ask user to create a recovery partition and MBR
read -p "Create a recovery partition?[y/N]" recovery_partition
[[ ! "${recovery_partition}" =~ ^([yY]|[nN])$ ]] && exit 1


### SET TIME AND SYNCHRONIZE SYSTEM CLOCK

timedatectl set-ntp true


### DISK PARTITIONING FORMATING AND MOUNTING

## Partitioning hdd (WITHOUT recovery partition)
if [[ ! "${recovery_partition}" =~ ^([yY][eE][sS]|[yY])$ ]]; then

  ## General Disk Partitioning Scheme: 2 partitions
  #  /boot (/dev/sdx1, 300MB)
  #  /root (/dev/sdx2, all remaining free disk space)

  ## Partitioning disk with MBR table:
  parted -s "${target_device}" mklabel msdos
  parted -s -a optimal "${target_device}" mkpart primary ext2 0% 300MB
  parted -s "${target_device}" set 1 boot on
  parted -s -a optimal "${target_device}" mkpart primary ext4 300MB 100%

  ## Formating partitions (-F=overwrite if necessary)
  mkfs.ext2 -F "${target_device}1"
  mkfs.ext4 -F "${target_device}2"
  
  ## Mounting partitions
  # partition "/"
  mount "${target_device}2" /mnt
  # partition "/boot"
  mkdir /mnt/boot
  mount "${target_device}1" /mnt/boot
fi

## Partitioning hdd (WITH RECOVERY PARTITION)
if [[ "${recovery_partition}" =~ ^([yY][eE][sS]|[yY])$ ]]; then

  ## General Disk Partitioning Scheme: 4 partitions
  #  /boot (/dev/sdx1, 300MB, shared between the /root )
  #  /home (/dev/sdx2, 3.7GB, shared between the /root directories)
  #  /root (/dev/sdx3, 4GB, original)
  #  /root (/dev/sdx4, 4GB, duplicate for recovery or testing purposes)

  ## Partitioning disk with MBR table:
  parted -s "${target_device}" mklabel msdos
  parted -s -a optimal "${target_device}" mkpart primary ext2 0% 300MB
  parted -s -a optimal "${target_device}" mkpart primary ext4 300MB 4GB
  parted -s -a optimal "${target_device}" mkpart primary ext4 4GB 8GB
  parted -s -a optimal "${target_device}" mkpart primary ext4 8GB 12GB


  ## Formating partitions (-F=overwrite if necessary)
  mkfs.ext2 -F "${target_device}1"
  mkfs.ext4 -F "${target_device}2"
  mkfs.ext4 -F "${target_device}2"
  mkfs.ext4 -F "${target_device}3"
  
  ## Mounting partitions
  # partition "/" original root partition
  mount "${target_device}3" /mnt
  # partition "/boot"
  mkdir /mnt/{boot,home}
  mount "${target_device}1" /mnt/boot
  mount "${target_device}2" /mnt/home
  # root partition duplicate for recovery and testing will be created
  # and mounted before bootloader configuration (see script2.sh)
fi



## Important: update package manager keyring
pacman -Syy --noconfirm archlinux-keyring


## install elementary system packages
# esential packages
pacstrap /mnt base base-devel linux
# editors
pacstrap /mnt vim nano
# system tools	
pacstrap /mnt zsh sudo git wget
# system mounting tools
pacstrap /mnt gvfs
# network
pacstrap /mnt dhcpcd
# wifi
pacstrap /mnt networkmanager
# boot loader	
pacstrap /mnt grub os-prober


## generate fstab
genfstab -L /mnt >> /mnt/etc/fstab


## copy script2.sh to new system
cp "${PWD}"/script2.sh /mnt/home || cp arch/script2.sh /mnt/home 


## change root and run script2.sh
arch-chroot /mnt sh /home/script2.sh \
	    "$target_device" \
	    "$host_name" \
	    "$root_password" \
	    "$user_name" \
	    "$user_password" \
	    "$user_shell" \
	    "$autolog_tty" \
	    "$recovery_partition"


## remove script
#rm /mnt/home/script2.sh

script_end_time="$(date +%s)"
runtime="$((${script_end_time}-${script_start_time}))"
printf "\n## Install runtime : $runtime\n" >> /mnt/home/script2.sh

## umount archlinux new system partition /mnt 
umount -R /mnt

reboot now

# Local Variables:
# sh-basic-offset: 2
# End:
