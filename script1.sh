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
if [[ "$EUID" -eq 0 ]]; then
  echo "./$0 require root priviledges"
fi 
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
function dialog_get_target_device
{
  ## function declaration
  function dialog_to_input_a_target_device
  {
    # Help the user showing the block devices available
    local array_of_block_devices=($(lsblk | awk '/disk/{ print $1 }'))
    printf "::List of block devices (lsblk):\n%s\n\n" "$(lsblk)"
    printf "::Choose a device to install archlinux on:\n"
    # The function help the user to choose and return a block device.
    local __resultvar="$1"
    local answer=" "
    until [[ "${answer}" =~ ^([yY])$ ]]; do
      select option in "${array_of_block_devices[@]}";do
	case "${option}" in
	  "")
	    printf "\nInvalid option: ${option}. Canceling install!\n\n"
	    exit 0
	    ;;
	  *)
	    eval "${__resultvar}"="/dev/${option}" \
	      || die "can not set value $_"
	    break
	    ;;
	esac
      done
      read -p "\n::Confirm install iso in ${__result}?[y/N]" answer
    done
    # choose installation target device
    # if mount | grep -q "${__result}"; then
    #   limit="$(($(mount | grep "${__result}" | wc -l )+1))"
    #   for ((i = "${limit}" ; i > 0  ; i--)); do
    # 	warning "${__result}${i} is mounted, umounting..."
    # 	umount "${__result}${i}" \
      # 	  || die "can not umount ${__result}"
    #   done
    #   printf "::List of block devices updated:\n%s\n\n" "$(lsblk)"
    # fi
  }
  # The functions result will be stored in the variable "__resultvar".
  # Thus, the "target_device" will have the value of "__resultvar".
  local __resultvar="$1"
  local __result=" "
  ## main code
  if [[ ! "${MACHINE}" == 'Real' ]]; then
    eval "${__resultvar}"=/dev/sda || die 'can not set var $target_device'
  else
    dialog_to_input_a_target_device __result
    eval "${__resultvar}"="${__result}"
  fi
}
########################################
# Purpose: ERROR HANDLING
# Requirements: None
########################################
out() { printf "$1 $2\n" "${@:3}"; }
error() { out "==> ERROR:" "$@"; } >&2
warning() { out "==> WARNING:" "$@"; } >&2
msg() { out "==>" "$@"; }
msg2() { out "  ->" "$@";}
die() { error "$@"; exit 1; }


### DECLARE VARIABLES


# variables fixed for archlinux install
user_shell=/bin/zsh		# examples: /bin/zsh; /bin/bash
keyboard_keymap=es		# examples: es; en; de; fr; it; 
local_time=/Europe/Berlin
SECONDS=0
# variables automatically recognized
machine="$(dmidecode -s system-manufacturer)" \
  || die "can not set variable ${machine}"
if [[ "${machine}" == 'innotek GmbH' ]]; then
  MACHINE='VBox' || die "can not set variable ${MACHINE}"
else
  MACHINE='Real' || die "can not set variable ${MACHINE}"
fi
# BIOS and UEFI support
if ! ls /sys/firmware/efi/efivars >& /dev/null; then
  boot_mode='BIOS' || die "can not set variable ${boor_mode}"
else
  boot_mode='UEFI' || die "can not set variable ${boor_mode}"
fi
# variables that user must provide (hide passwords by -sp option)
read -p "Enter hostname: " host_name \
  || die 'can not set variable ${host_name}'
read -sp "Enter ROOT password: " root_password \
  || die 'can not set variable ${root_password}'
read -p "Enter NEW user: " user_name \
  || die 'can not set variable ${user_name}'
read -sp "Enter NEW user PASSWORD: " user_password \
  || die 'can not set variable ${user_password}'
# variables that user must provide by dialog
target_device=" "; dialog_get_target_device target_device
drive_info="$(find /dev/disk/by-id/ -lname *${target_device##*/})" \
  || die 'can not set ${drive_info}'
if echo "${drive_info}" | grep -i -q 'usb\|mmcblk'; then
  drive_removable='yes' \
    || die 'can not set variable ${drive_removable}'
else
  drive_removable='no' \
    || die 'can not set variable ${drive_removable}'
fi


### EXPORT VARIABLES (required for script2.sh)

export host_name
export root_password
export user_name
export user_password
export user_shell
export target_device
export keyboard_keymap
export local_time
export MACHINE
export drive_removable


### SET TIME AND SYNCHRONIZE SYSTEM CLOCK

timedatectl set-ntp true \
  || die "can not set time/date"


### HDD PARTITIONING (BIOS/MBR)

## clear start
if mount | grep -q '/mnt'; then
  warning '/mnt is mounted, umounting /mnt...'
  umount -R /mnt && msg2 "done" || die 'can not umount /mnt'
fi


if [[ "${boot_mode}" == 'BIOS' ]]; then
  printf "BIOS detected! Choose GPT or MBR partition table:\n"
  select OPTION in MBR GPT; do
    case "${OPTION}" in
      MBR)
	## HDD partitioning (BIOS/MBR)
	parted -s "${target_device}" \
	       mklabel msdos \
	       mkpart primary ext4 0% 100% \
	       set 1 boot on \
	  && msg2 "%s successful MBR partitioned" "${target_device}" \
	    || die "Can not partition MBR %s" "${target_device}"
	## HDD formating (-F: overwrite if necessary)
	if [[ "${drive_removable}" == 'no' ]]; then
	  mkfs.ext4 -F "${target_device}1" \
	    || die "can not format $_"
	else
	  mkfs.ext4 -F -O "^has_journal" "${target_device}1" \
	    || die "can not format $_"
	fi
	## HDD mounting
	mount "${target_device}1" /mnt \
	  || die "can not mount ${target_device}1"
	break
	;;
      GPT)
	## HDD partitioning (BIOS/GPT)
	parted -s "${target_device}" mklabel gpt
	parted -s "${target_device}" mkpart primary ext3 64s 8MiB
	parted -s "${target_device}" set 1 bios_grub on
	parted -s "${target_device}" mkpart primary ext4 8MiB 12GiB
	parted -s "${target_device}" -- mkpart primary ext4 12GiB -1s
	parted -s "${target_device}" -a optimal \
	  && msg2 "%s : optimal aligned" "${target_device}" \
	    || die "%s : WRONG alignment" "${target_device}"
	
	## HDD formating (-F: overwrite if necessary)
	if [[ "${drive_removable}" == 'no' ]]; then
	  mkfs.ext4 -F "${target_device}2" \
	    || die "can not format $_"
	  mkfs.ext4 -F "${target_device}3" \
	    || die "can not format $_"
	else
	  mkfs.ext4 -F -O "^has_journal" "${target_device}2" \
	    || die "can not format $_"
	  mkfs.ext4 -F -O "^has_journal" "${target_device}3" \
	    || die "can not format $_"
	fi
	## HDD mounting
	mount "${target_device}2" /mnt \
	  || die "can not mount ${target_device}2"
	mkdir -p /mnt/home || die "can not create $_"
	mount "${target_device}3" /mnt/home \
	  || die "can not mount ${target_device}3"
	break
	;;
    esac
  done
fi


### REQUIREMENTS BEFORE SYSTEM PACKAGES INSTALLATION

## update keyring
pacman -Syy --noconfirm archlinux-keyring \
  || die 'can not updated keyring'


### SYSTEM PACKAGES INSTALLATION

## Essential Package List:
# base
Packages=('base' 'linux')
# development
Packages=('base-devel')
# virtualization
Packages=('linux-headers')
# shell 	
Packages+=('zsh')
# tools
Packages+=('sudo' 'git' 'wget' 'make')
# file manager
Packages+=('nemo')
# mounting tools for filemanagers
Packages+=('gvfs' 'udiskie')
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
if [[ "${boot_mode}" == 'UEFI' ]]; then Packages+=('efibootmgr'); fi
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
Packages+=('xorg-server' 'xorg-xrandr' 'xterm' 'xorg-xwininfo')
# Display driver - Nvidia support
if lspci -k | grep -e "3D.*NVIDIA" &>/dev/null; then
  [[ "${Packages[*]}" =~ 'linux-lts' ]] && Packages+=('nvidia-lts')
  [[ "${Packages[*]}" =~ 'linux' ]] && Packages+=('nvidia')
  # nvidia monitoring tool
  Packages+=('nvtop')
fi
# Desktop environment
Packages+=('xfce4')
Packages+=('xfce4-pulseaudio-plugin' 'xfce4-screenshooter')
Packages+=('pavucontrol' 'pavucontrol-qt' 'alsa-utils')
Packages+=('network-manager-applet')
Packages+=('papirus-icon-theme')
# add packages required for install in Real Machine or virtual (VBox)
## if Real Machine, install:
if [[ "${MACHINE}" == 'Real' ]]; then
  # hardware support packages
  Packages+=('linux-firmware')
  # video recorder
  Packages+=('obs-studio')
  # video players
  Packages+=('mpv' 'vlc')
  # Audio players
  Packages+=('audacious' 'audacity')
  # pdf viewer
  Packages+=('okular')
  # browser
  Packages+=('firefox')
  # text editor
  Packages+=('libreoffice-fresh' 'libreoffice-fresh-de')
  Packages+=('libreoffice-fresh-en-gb' 'libreoffice-fresh-es')
  # text edition - latex support
  # read -p "LATEX download take time. Install it anyway?[y/N]" response
  # [[ "${response}" =~ ^[yY]$ ]] \
    #   && Packages+=('texlive-core' 'texlive-latexextra')
fi
# if VirtualBox: install guest utils package
if [[ "${MACHINE}" == 'VBox' ]]; then Packages+=('virtualbox-guest-utils'); fi

## Packages Instalation - pacstrap
pacstrap /mnt --needed --noconfirm "${Packages[@]}" \
  || die 'Pacstrap can not install the packages'


### GENERATE FILE SYSTEM TABLE

genfstab -L /mnt >> /mnt/etc/fstab || die 'can not generate $_'

# if present, add aditional hardware to fstab 
# if [[ "${MACHINE}" == 'Real' ]]; then
#   # desired result:
#   #  LABEL=xxx /dir ext4 rw,nosuid,nodev,user_id=0,group_id=0,allow_other,blksize=4096 0 0
#   # code example:
#   #  mount --types ext4 /dev/sdxY /dir -o noatime,nodev,nosuid
#   mount_drive="$(lsblk -f | awk '/lack/{ print $0 }')" \
#     || die 'can not set ${mount_drive}'
#   if [[ -n "${mount_drive}" ]]; then
#     tmp_array=( $mount_drive )
#     my_drive="${tmp_array[0]:2}" || die 'can not set my_drive'
#     my_fs="${tmp_array[1]}" || die 'can not set my_fs'
#     my_label="${tmp_array[2]}" || die 'can not set my_label'
#     my_UUID="${tmp_array[3]}" || die 'can not set my_UUID'
#     my_path=/run/media/"${user_name}"/"${my_label}" \
# 	|| die 'can not set ${my_path} in ${my_drive}'
#       echo "# ${my_UUID}
# /dev/${my_drive:2} 									${my_path} 		${my_fs} 	uid=1000,gid=1000,umask=0022,fmask=133 	0 0
# " >> /etc/fstab || die "can not add ${my_drive} to $_"
#       unset my_path || die "can not unset $_"
#       unset mount_drive || die "can not unset $_"
#     fi
# fi


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
