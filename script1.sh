#!/bin/bash
#
# ./script1.sh is a script to install Arch Linux amd configure a desktop
#
# Summary:
# * contain all the commands required to prepare a system
#   for a new Arch Linux installation.
# * call the script2.sh which run arch-chroot
#   commands required to configure a new arch linux system.
# * call the script3.sh which run arch-chroot
#   commands required to select, install and customize a new desktop.
#
# Dependencies: None
# 
### CODE:

### Requirements:

# Root Privileges
if [[ "$EUID" -ne 0 ]]; then
  echo "ERROR: ./$0 require root priviledges"
  exit
elif ! pacman -S --needed --noconfirm dmidecode; then
  echo "ERROR: can not install required package dmidecode"
  exit
else
  read -p "Running $0. Do you want to INSTALL archlinux?[Y/n]" answer
  [[ "${answer:-N}" =~ ^([nN])$ ]] && echo "Quit.." | exit 0
  unset answer
fi


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
# Purpose: dialog to ask if user want to install a desktop
# Arguments: $1
# Return: the argument $1 will store the variable $install_desktop (e.g. 'y')
########################################
function dialog_ask_install_desktop
{
  cd desktop/
  system_desktop=" "
  local __resultvar="$1"
  local array_desktops=($(find . -mindepth 1 -maxdepth 1 -type d \
				 ! -iname "scripts-shared" \
			    | sed 's%./%%g'))
  read -p "==> Install ${array_desktops[0]} desktop? [Y/n]" install_desktop_default
  if [[ ! "${install_desktop_default}" =~ ^([nN])$ ]]; then
    system_desktop="${array_desktops[0]}" \
      || die "can not set $$system_desktop=$_"
    startcommand_xinitrc="$(cat ./"${array_desktops[0]}"/startcommand-xinitrc.sh)" \
      || die "can not set $$startcommand_xinitrc=$_"
    export system_desktop || die "can not export $_"
    export startcommand_xinitrc || die "can not export $_"
    eval "${__resultvar}"='y' \
      || die "can not set $$install_desktop to $_"
  else
    read -p "Do you want to install a desktop? [Y/n]" install_desktop
    if [[ ! "${install_desktop}" =~ ^([nN])$ ]]; then
      printf "please select a desktop:\n"
      until [[ "${__answer:-N}" =~ ^([yY])$ ]]; do
	select option in "${array_desktops[@]}"; do
	  case "${option}" in
	    "")
	      echo "::Incorrect option! Try again"
	      ;;
	    *)
	      system_desktop="${option}"
	      startcommand_xinitrc="$(cat ./"${option}"/startcommand-xinitrc.sh)"
	      break
	      ;;
	  esac
	done
	read -p "::Confirm install ${system_desktop}? [y/N]" __answer
      done
      # unset array_desktops || die "can not unset $_"
      export system_desktop || die "can not export $_"
      export startcommand_xinitrc || die "can not export $_"
      msg "${system_desktop} Confirmed!"
      eval "${__resultvar}"="${__answer}"
    else
      eval "${__resultvar}"='N'
    fi
  fi
  cd $OLDPWD
}

########################################
# Purpose: extract compressed files
# Requirements: None
########################################
function extract
{
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2)   tar xvjf "$1"    ;;
      *.tar.gz)    tar xvzf "$1"    ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar x "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xvf "$1"     ;;
      *.tbz2)      tar xvjf "$1"    ;;
      *.tgz)       tar xvzf "$1"    ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *)           echo "don't know how to extract '$1'..." ;;
    esac
  else
    echo "'$1' is not a valid file!"
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

## variables that user must provide (hide passwords by -sp option)
read -p "==> Enter hostname: " host_name \
  || die 'can not set variable ${host_name}'
read -sp "==> Enter ROOT password: " root_password \
  || die 'can not set variable ${root_password}'
read -p "==> Enter NEW user: " user_name \
  || die 'can not set variable ${user_name}'
read -sp "==> Enter NEW user PASSWORD: " user_password \
  || die 'can not set variable ${user_password}'

## variables automatically recognized
machine="$(dmidecode -s system-manufacturer)" \
  || die "can not set variable ${machine}"
if [[ "${machine}" == 'innotek GmbH' ]]; then
  MACHINE='VBox' || die "can not set variable ${MACHINE}"
else
  MACHINE='Real' || die "can not set variable ${MACHINE}"
fi

## BIOS and UEFI support
if ! ls /sys/firmware/efi/efivars >& /dev/null; then
  boot_mode='BIOS' || die "can not set variable ${boor_mode}"
  partition_table_default=MBR
  read -p "==> BIOS detected! select MBR or GPT partition table [${partition_table_default}]:" partition_table || die "can not read $_"
  partition_table=${partition_table:-$partition_table_default} \
     || die "can not set partition_table"
  unset partition_table_default || die "can not unset $_"
else
  boot_mode='UEFI' || die "can not set variable ${boor_mode}"
  partition_table=GPT
fi

## variables that user must confirm or edit
# shell
user_shell_default=/bin/bash	# examples: /bin/zsh; /bin/bash
read -p "==> Enter user shell [${user_shell_default}]: " user_shell \
     || die "can not set $_"
user_shell=${user_shell:-$user_shell_default} \
     || die "can not set user_shell"
unset user_shell_default || die "can not unset $_"
# keyboard
keyboard_keymap_default='es' \
  || die "can not set keyboard_keymap_default"
read -p "==> Enter system Keyboard keymap [${keyboard_keymap_default}]:" keyboard_keymap \
  || die "can not unset $_"
keyboard_keymap=${keyboard_keymap:-$keyboard_keymap_default}
unset keyboard_keymap_default || die "can not unset $_"
# local time
local_time_default=/Europe/Berlin
read -p "==> Enter local time [${local_time_default}]: " local_time
local_time=${local_time:-$local_time_default} \
     || die "can not set local_time"
unset local_time_default || die "can not unset $_"
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
# select and install arch linux desktop (required for script3.sh)
install_desktop=" "; dialog_ask_install_desktop install_desktop


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
export install_desktop


### SET TIME AND SYNCHRONIZE SYSTEM CLOCK

timedatectl set-ntp true \
  || die "can not set time/date"


## clear start
if mount | grep -q '/mnt'; then
  warning '/mnt is mounted, umounting /mnt...'
  umount -R /mnt && msg2 "done" || die 'can not umount /mnt'
fi


### HDD PARTITIONING 

## using: parted and grub
#souce: https://wiki.archlinux.org/title/Parted
#define maximum size of root partition = Root_Max
[[ "${MACHINE}" == 'Real' ]] && Root_Max=70GiB || Root_Max=15GiB
## BIOS
if [[ ${boot_mode} == 'BIOS' ]]; then
  if [[ ${partition_table} == 'MBR' ]]; then
    ### HDD PARTITIONING (BIOS/MBR)
    parted -s -a optimal "${target_device}" \
	   mklabel msdos \
	   mkpart primary ext4 0% "${Root_Max}" \
	   set 1 boot on \
	   mkpart primary ext4 "${Root_Max}" 100% \
      || die "can not create BIOS/MBR partition"
    parted -s "${target_device}" print

    ## HDD formating (-F: overwrite if necessary)
    if [[ "${drive_removable}" == 'no' ]]; then
      mkfs.ext4 -F "${target_device}1" \
	|| die "can not format $_"
      mkfs.ext4 -F "${target_device}2" \
	|| die "can not format $_"
    else
      mkfs.ext4 -F -O "^has_journal" "${target_device}1" \
	|| die "can not format $_"
      mkfs.ext4 -F -O "^has_journal" "${target_device}2" \
	|| die "can not format $_"
    fi

    ## HDD mounting
    mount "${target_device}1" /mnt \
      || die "can not mount ${target_device}1"
    mkdir -p /mnt/home || die "can not create $_"
    mount "${target_device}2" /mnt/home \
      || die "can not mount ${target_device}2"
    lsblk
    sleep 3
  fi

  if [[ ${partition_table} == 'GPT' ]]; then
    ## HDD partitioning (BIOS/GPT)
    parted -s -a optimal "${target_device}" mklabel gpt \
	   mkpart "BIOS" ext2 2MiB 4MiB \
	   set 1 bios_grub on \
	   mkpart "ROOT" ext4 4MiB "${Root_Max}" \
	   mkpart "HOME" ext4 "${Root_Max}" 100% \
      || die "can not create BIOS/GPT partition"
    parted -s "${target_device}" print

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
    parted -s "${target_device}" print

    ## HDD mounting
    mount "${target_device}2" /mnt \
      || die "can not mount ${target_device}2"
    mkdir -p /mnt/home || die "can not create $_"
    mount "${target_device}3" /mnt/home \
      || die "can not mount ${target_device}3"
    lsblk
    sleep 3
  fi
fi


### REQUIREMENTS BEFORE SYSTEM PACKAGES INSTALLATION

## record packages installation time
SECONDS=0

## update keyring
pacman -Syy --noconfirm archlinux-keyring \
  || die 'can not updated keyring'


### SYSTEM PACKAGES INSTALLATION

## Linux Essential Package List:
Packages=()
# base
Packages+=('base' 'linux')
# development
Packages+=('base-devel')
# virtualization
Packages+=('linux-headers')
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
# system info
Packages+=('dmidecode')
# multi-OS support
Packages+=('usbutils' 'dosfstools' 'ntfs-3g' 'amd-ucode' 'intel-ucode')
# backup
Packages+=('rsync')
# uncompress
Packages+=('unzip' 'unrar')
# linux man pages
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

## Graphical User Interface - Global packages
# Display server - xorg (because wayland lack support for nvidia CUDA)
Packages+=('xorg-xinit' 'xorg-server' 'xorg-xrandr' 'xterm')
# Display driver - Nvidia support
if lspci -k | grep -e "3D.*NVIDIA" &>/dev/null; then
  [[ "${Packages[*]}" =~ 'linux-lts' ]] && Packages+=('nvidia-lts')
  [[ "${Packages[*]}" =~ 'linux' ]] && Packages+=('nvidia')
  # nvidia monitoring tool
  Packages+=('nvtop')
fi
# icon theme
Packages+=('papirus-icon-theme')

## add packages required for install in Real Machine or virtual (VBox)
# if Real Machine, install:
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
if [[ "${MACHINE}" == 'VBox' ]]; then
  Packages+=('virtualbox-guest-utils')
fi

## Desktop Packages installation
if [[ "${install_desktop}" =~ ^([yY])$ ]]; then
  # data_dir="$(dirname $(realpath $0))/${system_desktop}"
  # readarray -t DesktopPkg < "${data_dir}"/pkglist.txt
  readarray -t DesktopPkg < ./desktop/"${system_desktop}"/pkglist.txt
  Packages+=(${DesktopPkg[@]})
fi

## System Packages Installation
pacstrap /mnt --needed --noconfirm "${Packages[@]}" \
  || die "Pacstrap can not install the packages $_"


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

# copy and run script2.sh to configure the new Arch Linux system
cp ./script2.sh /mnt/home || die "can not copy script2.sh to $_"
arch-chroot /mnt bash /home/script2.sh || die "can not run arch-root $_"
# remove script2.sh after finish
rm /mnt/home/script2.sh || die "can not remove $_"


### DOTFILES

# copy dotfiles to new system
cp ./dotfiles/.[a-z]* /mnt/home/"${user_name}" || die 'can not copy $_'
# create the folder Project in $HOME
my_path=/mnt/home/"${user_name}"/Projects/archlinux
mkdir -p "${my_path}" || die "can not create $_"
# backup archlinux repo inside ~/Projects folder
cp -r . "${my_path}" || die "can not backup archlinux repo"
# backup the scripts used during arch linux installation
my_path=/mnt/home/"${user_name}"/Projects/archlinux_install_report
mkdir -p "${my_path}" || die "can not create $_"
cp ./script[1-2].sh "${my_path}" || die "can not copy $_"
cp ./desktop/"${system_desktop}"/script3.sh "${my_path}" \
  || die "can not copy $_"
duration=$SECONDS || die 'can not set variable $duration'
echo "user_name=${user_name}
MACHINE=${MACHINE}
script1_time_seconds=${duration}
" > "${my_path}"/installation_report || die "can not create $_"
chmod +x "${my_path}"/installation_report \
  || die "can not set executable $_"
unset my_path || die "can not unset $_"


### BIN SCRIPTS

if [[ "${install_desktop}" =~ ^([yY])$ ]]; then
  my_path=/mnt/home/"${user_name}"/bin
  mkdir -p "${my_path}" || die "can not create $_"
  cp -r ./desktop/scripts-shared "${my_path}" \
    || die "Pacstrap can not install the packages $_"
fi

# correct user permissions
arch-chroot /mnt bash -c "\
chown -R ${user_name}:${user_name} /home/${user_name}/.[a-z]*;\
chown -R ${user_name}:${user_name} /home/${user_name}/[a-zA-Z]*;\
chown -R ${user_name}:${user_name} /home/${user_name}/Down*/*;" \
  || die 'can not correct user permissions in /home/user'


### UNMOUNT EVERYTHING AND REBOOT
read -p "$0 install succeded (${duration} seconds)! umount '/mnt' and reboot?[Y/n]" response
[[ "${response}" =~ ^([nN])$ ]] && umount -R /mnt | reboot now


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
