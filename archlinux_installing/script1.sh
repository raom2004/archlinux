#!/bin/bash
#
# script1.h: bash script for install archlinux with support for BIOS/MBR 

## start meassuring time of execution
start="$(date +%s)"


## set bash options for: debugging

set -o errtrace # inherit any trap on ERROR
set -o functrace # inherit any trap on DEBUG and RETURN
set -o errexit  # EXIT if script command fails
set -o nounset  # EXIT if script try to use undeclared variables
set -o pipefail # CATCH failed piped commands
set -o xtrace   # trace & expand what gets executed (useful for debugging)

## Usage

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

## Validate mountpoint

function ask_for_mountpoint {

  # initialize mountpoint
  mountpoint=""

  # find mountpoints available
  maxdrive="$(lsblk | awk '/sd[a-z] /{ print substr($1, 3) }' | tail -n1)"
  drives_available="$(lsblk | awk '/sd[a-z] /{ printf "/dev/" $1 "  "}')"

  # show mountpoints available
  printf "\nTable of Mountpoints Avaliable:\n\n%s\n\n" "$(lsblk)"
  printf "Drives available: ${Blue}%s${NC}\n\n" "${drives_available}"

  # ask for a mountpoint
  until [[ "${mountpoint}" =~ ^/dev/sd[a-${maxdrive}]$ ]]
  do
    printf "Please introduce a mountpoint"
    printf " (${Green}example:/dev/sd${maxdrive}${NC}):${Green}" 
    read -i '/dev/sd' -e mountpoint
    printf "${NC}"
    if [[ ! "${mountpoint}" =~ ^/dev/sd[a-${maxdrive}]$ ]]; then
      printf "${Red}ERROR:${NC} invalid mountpoint:"
      printf " ${Red}%s${NC}\n" "${mountpoint}"
      printf "Try with the drives available: ${Blue}%s${NC}\n\n" "${drives_available}"
    else
      # printf "Partition valid\n"
      printf "Confirm Installing Archlinux in "
      printf "${Green}${mountpoint}${NC} [y/N]?"
      read -e answer
      [[ ! "$answer" =~ ^([yY][eE][sS]|[yY])$ ]] && mountpoint="" 
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

case "${#}" in

  0)
    # 0 Arguments? please ask for them  
    read -p "Enter hostname: " host_name
    read -sp "Enter ROOT password: " root_password
    read -p "Enter NEW user: " user_name
    read -sp "Enter NEW user PASSWORD: " user_password
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
    display_usage
    exit 0
    ;;
  
esac





## Ask for mountpoint to install archlinux

case "${machine}" in

  REAL)
    ask_for_mountpoint
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

## list of packages to be installed
touch requirements.txt
# esential packages
cat <<EOF >> requirements.txt
base
base-devel
linux
EOF

# editors
cat <<EOF >> requirements.txt
vim
nano
EOF

# system tools	
cat <<EOF >> requirements.txt
zsh
sudo
git
wget
EOF
# system mounting tools
cat <<EOF >> requirements.txt
gvfs
EOF

# network
cat <<EOF >> requirements.txt
dhcpcd
EOF

# wifi
cat <<EOF >> requirements.txt
networkmanager
EOF

# boot loader	
cat <<EOF >> requirements.txt
grub
os-prober
EOF

## install system packages
pacstrap /mnt - < requirements.txt
 
## generate fstab
genfstab -L /mnt >> /mnt/etc/fstab


## copy scripts to new system
cp arch/script2.sh /mnt/home || cp "${PWD}"/script2.sh /mnt/home


## change root and run script
arch-chroot /mnt sh /home/script2.sh \
	    "$host_name" \
	    "$root_password" \
	    "$user_name" \
	    "$user_password" \
	    "$mountpoint"


## remove script
#rm /mnt/home/script2.sh

end="$(date +%s)"
runtime="$((${end}-${start}))"
echo "# $runtime" >> /mnt/home/script2.sh

umount -R /mnt
reboot now
# Local Variables:
# sh-basic-offset: 2
# End:
