#!/bin/bash
#
# ./script1.sh is a script to install Arch Linux amd configure a desktop
#
# Summary:
# * The script1.sh contain all the commands required to prepare a system
#   for a new Arch Linux installation.
# * The script1.sh also call the script2.sh which run arch-chroot
#   commands required to customize the new arch linux system.
#
# Dependencies: None
# 
### Requirements:

## Root Privileges
if [[ "$EUID" -eq 0 ]]; then echo "./$0 require root priviledges"; fi 
pacman -S --noconfirm dmidecode \
  || die 'can not install dmidecode required to identify actual system'


### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING ###################

# shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


### DECLARE FUNCTIONS

########################################
# Purpose: dialog to select a target block device for archlinux install
# Arguments: $1
# Return: the argument $1 will store a valid block device (e.g. /dev/sdX)
########################################
function dialog_to_input_a_target_device
{
  # The functions result will be stored in the variable "__resultvar".
  local __resultvar="$1"
  # Help the user showing the block devices available
  local array_of_block_devices=($(lsblk | awk '/disk/{ print $1 }'))
  printf "::List of block devices (lsblk):\n%s\n\n" "$(lsblk)"
  printf "::Choose a device to install archlinux on:\n"
  # The function help the user to choose and return a block device.
  select option in "${array_of_block_devices[@]}";do
    case "${option}" in
      "")
	printf "\nInvalid option. Canceling install!\n\n"
	exit 0
	;;
      *)
	# The function can't set a variable directly, but EVAL can:
	eval "${__resultvar}"="/dev/${option}"
	break
	;;
    esac
  done
}
########################################
# Purpose: ERROR HANDLING
# Requirements: None
########################################
out() { printf "$1 $2\n" "${@:3}"; }
error() { out "==> ERROR:" "$@"; } >&2
warning() { out "==> WARNING:" "$@"; } >&2
msg() { out "==>" "$@"; }
# msg2() { out "  ->" "$@";}
die() { error "$@"; exit 1; }


### DECLARE VARIABLES

# Hide passwords by -sp option
read -p "Enter hostname: " host_name
read -sp "Enter ROOT password: " root_password
read -p "Enter NEW user: " user_name
read -sp "Enter NEW user PASSWORD: " user_password
user_shell=/bin/zsh
keyboard_keymap=es
local_time=/Europe/Berlin
SECONDS=0

machine="$(dmidecode -s system-manufacturer)"
[[ "${machine}" == "innotek GmbH" ]] && MACHINE='VBox' || MACHINE='Real'
export MACHINE
if [[ ! "${MACHINE}" == 'Real' ]]; then
  hdd_partitioning=/dev/sda
else
  # choose installation target device
  printf "Installing archlinux iso in ${target_device}\n"
  response=" "
  until [[ "${answer}" =~ ^([yY])$ ]]; do
    dialog_to_input_a_target_device hdd_partitioning
    read -p "Confirm install iso in ${hdd_partitioning}?[y/N]" answer
  done
  # umount target device, if mounted previously
  if mount | grep -q "${hdd_partitioning}"; then
    limit="$(($(mount | grep "${hdd_partitioning}" | wc -l )+1))"
    for ((i = 1 ; i < "${limit}" ; i++)); do
      warning " ${hdd_partitioning}${limit} is mounted, umounting..."
      sudo umount "${hdd_partitioning}${i}" \
	|| die "can not umount ${target_device}"
    done
    printf "::List of block devices available:\n%s\n\n" "$(lsblk)"
  fi
fi


### EXPORT VARIABLES (required for script2.sh)

export host_name
export root_password
export user_name
export user_password
export user_shell
export hdd_partitioning
export keyboard_keymap
export local_time


### SET TIME AND SYNCHRONIZE SYSTEM CLOCK

timedatectl set-ntp true


### HDD PARTITIONING (BIOS/MBR)

## clear start
if mount | grep -q "/mnt"; then
  warning " /mnt is mounted, umounting /mnt..."
  umount -R /mnt || die "can not umount /mnt"
  msg "done"
fi

## HDD partitioning
parted -s "${hdd_partitioning}" \
       mklabel msdos \
       mkpart primary ext2 0% 2% \
       set 1 boot on \
       mkpart primary ext4 2% 100% \
  || die "Can not partition the drive %s" "${hdd_partitioning}"

## HDD patitions formating (-F=overwrite if necessary)
mkfs.ext2 -F "${hdd_partitioning}1" || die "can not format $_"
mkfs.ext4 -F "${hdd_partitioning}2" || die "can not format $_"

## HDD partitions mounting
# root partition "/"
mount "${hdd_partitioning}2" /mnt \
  || die "can not mount $_ in ${hdd_partitioning}2"
# boot partition "/boot"
mkdir /mnt/boot || die "can not create discrete partition $_"
mount "${hdd_partitioning}1" /mnt/boot \
  || die "can not mount $_ in ${hdd_partitioning}1"


### REQUIREMENTS BEFORE SYSTEM PACKAGES INSTALLATION

## update keyring
pacman -Syy --noconfirm archlinux-keyring \
  || die 'can not install updated pacman keyring'

## Get Current Boot Mode:
if ! ls /sys/firmware/efi/efivars 2>/dev/null; then
  boot_mode='BIOS'
else
  boot_mode='UEFI'
fi


### SYSTEM PACKAGES INSTALLATION

## Essential Package List:
# base
Packages=('base' 'linux')
# shell 	
Packages+=('zsh')
# tools
Packages+=('sudo' 'git' 'wget')
# mounting tools (required for filemanagers)
Packages+=('gvfs')
# lightweight text editors
Packages+=('vim')
# lightweight image editors
Packages+=('imagemagick' 'gpicview')
# network
Packages+=('dhcpcd')
# wifi
Packages+=('networkmanager')
# boot loader
Packages+=('grub' 'os-prober')
# UEFI boot support
[[ "${boot_mode}" == 'UEFI' ]] && Packages+=('efibootmgr')
# multi-OS support
Packages+=('usbutils' 'dosfstools' 'ntfs-3g' 'amd-ucode' 'intel-ucode')
# backup
Packages+=('rsync')
# uncompress
Packages+=('unzip' 'unrar')
# manual pages
Packages+=('man-db')
# glyphs support
Packages+=('ttf-dejavu'
           'ttf-hanazono'
	   'ttf-font-awesome'
	   'ttf-ubuntu-font-family'
	   'noto-fonts')
# heavy text editors
Packages+=('emacs')
# format conversion
Packages+=('pandoc')
# grammar corrector (for: Firefox, Thunderbird, Chromium and LibreOffice)
Packages+=('hunspell'
	   'hunspell-en_gb'
	   'hunspell-en_us'
	   'hunspell-de'
	   'hunspell-es_es')

## Graphical User Interface:
# Display server - xorg (because wayland has not support nvidia CUDA yet)
Packages+=('xorg-server' 'xorg-xrandr' 'xterm')
# Display driver - Nvidia support
if lspci -k | grep -e "3D.*NVIDIA" &>/dev/null; then
  [[ "${Packages[*]}" =~ 'linux-lts' ]] && Packages+=('nvidia-lts')
  [[ "${Packages[*]}" =~ 'linux' ]] && Packages+=('nvidia')
fi
# Desktop environment
Packages+=('xfce4')
Packages+=('xfce4-pulseaudio-plugin' 'xfce4-screenshooter')
Packages+=('pavucontrol' 'pavucontrol-qt')
Packages+=('papirus-icon-theme')
# add packages required for install in Real Machine or virtual (VBox)
## if Real Machine, install:
if [[ "${MACHINE}" == "Real" ]]; then
  # hardware support packages
  Packages+=('linux-firmware')
  # text edition - latex support
  read -p "LATEX download take time. Install it anyway?[y/N]" response
  [[ "${response}" =~ ^[yY]$ ]] \
    && Packages+=('texlive-core' 'texlive-latexextra')
fi
# if VirtualBox: install guest utils package
[[ "${MACHINE}" == "VBox" ]] && Packages+=('virtualbox-guest-utils')

## Packages Instalation - pacstrap
pacstrap /mnt --needed --noconfirm "${Packages[@]}" \
  || die 'Pacstrap can not install the packages'


### GENERATE FILE SYSTEM TABLE

genfstab -L /mnt >> /mnt/etc/fstab || die 'can not generate $_'


### SCRIPTING INSIDE CHROOT

# copying and running script2.sh
cp ./script2.sh /mnt/home || die "can not copy script2.sh to $_"
arch-chroot /mnt bash /home/script2.sh || die "can not run arch-root $_"
# removing script2.sh after finish
rm /mnt/home/script2.sh || die "can not remove $_"


### DESKTOP CUSTOMIZATION ON STARTUP

# run script3.sh containing user desktop customization (not root)
# option 1: /home/user/Projects/archlinux/script3.sh
# option 2 (deprecated): /home/user/script3.sh
# cp ./script3.sh /mnt/home/"${user_name}"/script3.sh \
#   || die "can not copy $_"
# chmod +x /mnt/home/"${user_name}"/script3.sh \
#   || die "can not set executable $_"


### DOTFILES

# copy dotfiles to new system
cp ./dotfiles/.[a-z]* /mnt/home/"${user_name}" || die 'can not copy $_'
# create the folder Project in $HOME
my_path=/mnt/home/"${user_name}"/Projects/archlinux
mkdir -p "${my_path}" || die "can not create $_"
# backup archlinux repo inside ~/Projects folder
cp -r . "${my_path}" || die "can not backup archlinux repo"
# make a backup of the scripts used during this arch linux install
my_path=/mnt/home/"${user_name}"/Projects/archlinux_install_report
mkdir -p "${my_path}"  || die "can not create $_"
cp ./script[1-3].sh "${my_path}"  || die "can not copy $_"
duration=$SECONDS || die 'can not set variable $duration'
echo "user_name=${user_name}
MACHINE=${MACHINE}
script1_time_seconds=${duration}
" > "${my_path}"/installation_report || die "can not create $_"
chmod +x "${my_path}"/installation_report \
  || die "can not set executable $_"
unset my_path || die "can not unset $_"


# correct user permissions
arch-chroot /mnt bash -c "\
chown -R ${user_name}:${user_name} /home/${user_name}/.[a-z]*;\
chown -R ${user_name}:${user_name} /home/${user_name}/[a-zA-Z]*;" \
  || die 'can not correct user permissions in /home/user'


### UNMOUNT EVERYTHING AND REBOOT

read -p "Install successful! umount '/mnt' and reboot?[y/N]" response
[[ "${response}" =~ ^[yY]$ ]] && umount -R /mnt | reboot now


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
