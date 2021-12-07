#!/bin/bash
#
# script1.h: bash script for install archlinux with support for BIOS/MBR 


### BASH SCRIPT1.SH OPTIONS ##########################################


## options for DEBUGGING

set -o errtrace # inherit any trap on ERROR
set -o functrace # inherit any trap on DEBUG and RETURN
set -o errexit  # EXIT if script command fails
set -o nounset  # EXIT if script try to use undeclared variables
set -o pipefail # CATCH failed piped commands
set -o xtrace   # trace & expand what gets executed (useful for debugging)

## script variables
script1_version="v0.8.0"
script_start_time="$(date +%s)"

### FUNCTIONS DECLARATION ############################################


## Bash Script Usage

function display_usage {

  printf "
ARCHLINUX installer version %s, with support for removable drive booting:

Usage: ${0##*/}

You can preconfig the installation, calling script1.sh with 4 arguments

Example 1:
$ sh script1.sh host-name root-password user-name user-password

Or without arguments. The script1.sh will ask the configuration on demand
Example 2:
$ sh script1.sh

" "${script1_version}"

}

## User must select a archlinux install: mountpoint

function ask_user_for_archlinux_install_mountpoint {

  # initialize mountpoint
  mountpoint=""

  # find mountpoints available
  maxdrive="$(lsblk | awk '/sd[a-z] /{ print substr($1, 3) }' | tail -n1)"
  drives_available="$(lsblk | awk '/sd[a-z] /{ printf "/dev/" $1 "  "}')"

  # show mountpoints available
  printf "\nTable of Mountpoints Avaliable:\n\n%s\n\n" "$(lsblk)"
  printf "Drives available: ${Blue}%s${NC}\n\n" "${drives_available}"

  # LOOP to ask user for mountpoint
  until [[ "${mountpoint}" =~ ^/dev/sd[a-${maxdrive}]$ ]]
  do
    printf "Please introduce a mountpoint"
    printf " (${Green}example:/dev/sd${maxdrive}${NC}):${Green}" 
    read -i '/dev/sd' -e mountpoint
    printf "${NC}"
    # if mount point invalid: show a message with mountpoint suggestions
    if [[ ! "${mountpoint}" =~ ^/dev/sd[a-${maxdrive}]$ ]]; then
      printf "${Red}ERROR:${NC} invalid mountpoint:"
      printf " ${Red}%s${NC}\n" "${mountpoint}"
      printf "Try with the drives available:"
      printf " ${Blue}%s${NC}\n\n" "${drives_available}"
    else
      # if mountpoint valid: please ask to confirm
      printf "Confirm Installing Archlinux in "
      printf "${Green}${mountpoint}${NC} [y/N]?"
      read -e answer
      [[ ! "${answer}" =~ ^([yY][eE][sS]|[yY])$ ]] && mountpoint="" 
    fi
  done

}



## Check Actual Machine: VirtualBox (VBox) vs REAL

pacman -Sy --noconfirm --needed dmidecode
check="$(dmidecode -s system-manufacturer)"
[[ "${check}" == "innotek GmbH" ]] && machine='VBox' || machine='REAL'


## Check if system supports boot as: BIOS or UEFI

if ! ls /sys/firmware/efi/efivars 2>/dev/null;then
  boot_mode='BIOS'
else
  boot_mode='UEFI'
fi


## Check if user provided script with: ARGUMENTS

display_usage

case "${#}" in

  0)
    # 0 Arguments? please ask for them
    read -p "Enter hostname: " host_name
    read -sp "Enter ROOT PASSWORD: " root_password
    read -p "Enter USER name: " user_name
    read -sp "Enter USER PASSWORD: " user_password
    ;;

  4)
    # 4 Arguments: convert it into log variables
    host_name="${1}"
    root_password="${2}"
    user_name="${3}"
    user_password="${4}"
    ;;

  *)
    printf "User provided wrong number of arguments (${#}). Exiting.."
    exit 0
    ;;
  
esac





## Ask for mountpoint to install archlinux

case "${machine}" in

  REAL)
    ask_user_for_archlinux_install_mountpoint
    ;;

  VBox)
    mountpoint=/dev/sda
    ;;
  
esac


## set time and synchronize system clock
timedatectl set-ntp true


## partition hdd
parted -s /dev/sda \
       mklabel msdos \
       mkpart primary ext2 0% 2% \
       set 1 boot on \
       mkpart primary ext4 2% 100%


## formating hdd (-F=overwrite if necessary)
mkfs.ext2 -F /dev/sda1
mkfs.ext4 -F /dev/sda2


## mount new partitions
# partition "/"
mount /dev/sda2 /mnt
# partition "/boot"
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot


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
	    "$host_name" \
	    "$root_password" \
	    "$user_name" \
	    "$user_password" \
	    "$mountpoint"


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
