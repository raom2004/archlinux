#!/bin/bash
#
# script1.h: bash script for install archlinux with support for BIOS/MBR 

# Dependencies:
#  built-in files (see above)


### BASH OPTIONS FOR SECURITY AND DEBUGGING ##########################

# shopt -o noclobber # prevent file overwriting (>) but can forced by (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


###  DEPENDENCIES ####################################################

source ./include/ANSI_escape_colors
source ./include/functions


### FUNCTION DECLARATION

########################################
# Purpose: dialog to input a target device for archlinux install
# Arguments: $1
# Return: $1
########################################

function dialog_to_input_a_target_device
{
  # The function's result will be set as the variable "__resultvar", but
  # a function can't set a variable directly but EVAL can do the setting:
  local __resultvar="${1}"
  local myarray=($(lsblk | awk '/disk/{ print $1 }'))
  printf "List block devices (lsblk):\n%s\n\n" "$(lsblk)"
  printf "Between the block devices detailed bellow,\n"
  printf "choose a device to install archlinux on:\n"
  select option in "${myarray[@]}";do
    case "${option}" in
      "") printf "\nWrong answer. Canceling install!\n\n"; exit 0 ;;
      *) eval "${__resultvar}"="/dev/${option}"; break ;;
    esac
  done
}


######################################################################
### CODE #############################################################
######################################################################


## Variables Declaration

script1_version="v0.8.0"
script_start_time="$(date +%s)"


## Argument hadling

# display usage if user provided the tag help
[[ "${1}" =~ (--help)|(-h) ]] && display_usage | exit 0 || &> /dev/null


## Check Actual Machine: Virtualbox vs REAL, BIOS vs UEFI

# VirtualBox (VBox) vs REAL
pacman -Sy --noconfirm --needed dmidecode
check="$(dmidecode -s system-manufacturer)"
[[ "${check}" == "innotek GmbH" ]] && machine='VBox' || machine='REAL'


# ## TODO: Check boot system support: BIOS or UEFI
# if ! ls /sys/firmware/efi/efivars 2>/dev/null;then
#   boot_mode='BIOS'
# else
#   boot_mode='UEFI'
# fi


## Check if user provided script with: ARGUMENTS

case "${#}" in

  7)
    # User provided 7 arguments, convert it into script variables
    target_device="${1}"	# e.g.: /dev/sdX
    host_name="${2}"		# any string
    root_password="${3}"	# any string
    user_name="${4}"		# any string
    user_password="${5}"	# any string
    user_shell="${6}"		# options: bash, zsh
    autolog_tty="${7}"		# options: yes, no
    ;;

  0)
    ## User do not provide arguments? please ask for them
    prinf "${Green}The archlinux install required some parameters:${NC}"

    # dialog to choose a target device (/dev/sdX) to install linux on
    [[ "${machine}" == 'REAL' ]] \
      && dialog_to_input_a_target_device target_device
    # in VirtualBox machine please set target device without dialog
    [[ "${machine}" == 'VBox' ]] && target_device=/dev/sda

    # log parameters, passwords are hidden (read -s)
    read -p "Enter HOST name: " host_name
    read -sp "Enter ROOT PASSWORD: " root_password
    read -p "Enter USER name: " user_name
    read -sp "Enter USER PASSWORD: " user_password

    # parameters with fixed options that need to be checked
    read -p "Enter USER SHELL (e.g. bash, zsh) " user_shell
    [[ ! "${user_shell}" =~ ^([b][a]|[z])(sh)$ ]] && echo "fail" | exit 1
    read -p "Do you want autolog tty at startup?[y/N]" autolog_tty
    [[ ! "${autolog_tty}" =~ ^([yY]|[nN])$ ]] && echo "fail" | exit 1
    ;;

  *)
    printf "User provided a wrong number of arguments (${#}). Cancel..\n"
    exit 0
    ;;
  
esac


## set time and synchronize system clock
timedatectl set-ntp true


## partition hdd
parted -s "${target_device}" mklabel msdos
parted -s -a optimal "${target_device}" mkpart primary ext2 0% 300MiB
parted -s "${target_device}" set 1 boot on
parted -s -a optimal "${target_device}" mkpart primary ext4 300MiB 100%


## formating hdd (-F=overwrite if necessary)
mkfs.ext2 -F "${target_device}1"
mkfs.ext4 -F "${target_device}2"


## mount new partitions
# partition "/"
mount "${target_device}2" /mnt
# partition "/boot"
mkdir /mnt/boot
mount "${target_device}1" /mnt/boot


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
	    "$autolog_tty"


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
