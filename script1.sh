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


### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING ###########

# shopt -o noclobber # file overwriting (>) only if forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if command fails
set -o nounset     # EXIT if try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # TRACE & EXPAND what gets executed


### DECLARE FUNCTIONS

########################################
# Purpose: ERROR HANDLING
# Requirements: None
########################################
## ERROR HANDLING
function out     { printf "$1 $2\n" "${@:3}"; }
function error   { out "==> ERROR:" "$@"; } >&2
function die     { error "$@"; exit 1; }
## MESSAGES
function warning { out "==> WARNING:" "$@"; } >&2
function msg     { out "==>" "$@"; }
function msg2    { out "  ->" "$@"; }
# function die {
#   # if error, exit and show file of origin, line number and function
#   # colors
#   NO_FORMAT="\033[0m"
#   C_RED="\033[38;5;9m"
#   C_YEL="\033[38;5;226m"
#   # color functions
#   function msg_red { printf "${C_RED}${@}${NO_FORMAT}"; }
#   function msg_yel { printf "${C_YEL}${@}${NO_FORMAT}"; }
#   # error detailed message (colored)
#   msg_red "==> ERROR: " && printf " %s" "$@" && printf "\n"
#   msg_yel "  -> file: " && printf "${BASH_SOURCE[1]}\n"
#   msg_yel "  -> func: " && printf "${FUNCNAME[2]}\n"
#   msg_yel "  -> line: " && printf "${BASH_LINENO[1]}\n"
#   exit 1
# }


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
	      || die
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
      # 	  || die
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
    eval "${__resultvar}"=/dev/sda || die
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
  array_desktops+=('none')
  printf "please select a desktop:\n"
  until [[ "${__answer:-}" =~ ^([yY])$ ]]; do
    select option in "${array_desktops[@]}"; do
      case "${option}" in
	"")
	  echo "::Incorrect option! Try again"
	  ;;
	"none")
	  system_desktop="${option}"
	  break
	  ;;
	*)
	  system_desktop="${option}"
	  startcommand_xinitrc="$(cat ./"${option}"/startcommand-xinitrc.sh)"
	  break
	  ;;
      esac
    done
    read -p "::Confirm install ${system_desktop} desktop? [y/N]" __answer
  done
  msg "${system_desktop} desktop confirmed!"
  if [[ "${system_desktop}" == 'none' ]]; then
    eval "${__resultvar}"='N'
  else
    export system_desktop || die
    export startcommand_xinitrc || die
    eval "${__resultvar}"="${__answer}"
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
# Purpose: declare variable if minimun lenght is ok
# Arguments: $1=variable name; $2=minimum length
# Return: $1 will become a variable name with a $variable_value
# Usage: variable_declaration host_name HostName
# host_name=" "; variable_declaration host_name 2
#  after call the function if variable leght
########################################

function variable_declaration {
  local __resultvar="$1"
  local min_legth="$2"
  local hide="${3:-}"
  local variable_value="${variable_value:-}"
  until (( "${#variable_value}" > "${min_legth}" )); do
    if [[ "${hide}" == 'hide' ]]; then
      read -sp "==> Enter ${__resultvar^^}: " variable_value \
	|| die
    else
      # (hide passwords by using -sp option)'
      read -p "==> Enter ${__resultvar^^}: " variable_value \
	|| die
    fi
    if (( "${#variable_value}" < "${min_legth}" || "${#variable_value}" == "${min_legth}" ))
    then
      warning "invalid length (${#variable_value}), required (>${min_legth})"
    else
      eval "${__resultvar}"="${variable_value}" || die
      msg2 "variable declared ${__resultvar} correct!"
    fi
  done
}

#### MAIN CODE #############################################
############################################################

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

### DECLARE VARIABLES

## variables declared by function 
variable_declaration host_name 2
variable_declaration root_password 6 hide
variable_declaration user_name 2
variable_declaration user_password 6 hide

## variables automatically recognized
machine="$(dmidecode -s system-manufacturer)" \
  || die
if [[ "${machine}" == 'innotek GmbH' ]]; then
  MACHINE='VBox' || die
else
  MACHINE='Real' || die
fi

## BIOS and UEFI support
if ! ls /sys/firmware/efi/efivars >& /dev/null; then
  boot_mode='BIOS' || die
  partition_table_default=MBR
  read -p "==> BIOS detected! select MBR or GPT partition table [${partition_table_default}]:" partition_table || die
  partition_table=${partition_table:-$partition_table_default} \
     || die
  unset partition_table_default || die
else
  boot_mode='UEFI' || die
  partition_table=GPT
fi

## variables that user must confirm or edit
# shell
user_shell_default=/bin/bash	# examples: /bin/zsh; /bin/bash
read -p "==> Enter user shell [${user_shell_default}]: " user_shell || die
user_shell=${user_shell:-$user_shell_default} || die
unset user_shell_default || die
# keyboard
keyboard_keymap_default='es' \
  || die
read -p "==> Enter system Keyboard keymap [${keyboard_keymap_default}]:" keyboard_keymap || die
keyboard_keymap=${keyboard_keymap:-$keyboard_keymap_default}
unset keyboard_keymap_default || die
# local time
local_time_default=/Europe/Berlin
read -p "==> Enter local time [${local_time_default}]: " local_time
local_time=${local_time:-$local_time_default} || die
unset local_time_default || die
# variables that user must provide by dialog
# target_device=" "; dialog_get_target_device target_device
# drive_info="$(find /dev/disk/by-id/ -lname *${target_device##*/})" \
  # || die
# if echo "${drive_info}" | grep -i -q 'usb\|mmcblk'; then
  # drive_removable='yes' \
    # || die
# else
  # drive_removable='no' \
    # || die
# fi
# select and install arch linux desktop (required for script3.sh)
install_desktop=" "; dialog_ask_install_desktop install_desktop


### EXPORT VARIABLES (required for script2.sh)

export host_name
export root_password
export user_name
export user_password
export user_shell
# export target_device
export keyboard_keymap
export local_time
export MACHINE
export drive_removable
export install_desktop


### SET TIME AND SYNCHRONIZE SYSTEM CLOCK

timedatectl set-ntp true \
  || die


## clear start
if mount | grep -q '/mnt'; then
  warning '/mnt is mounted, umounting /mnt...'
  umount -R /mnt && msg2 "done" || die
fi


### SSD PARTITIONING (BIOS/MBR)


## SSD partitioning: root "/" in ssd in free space (/dev/sdc3)

# parted -s -a optimal /dev/sdc \
#        mkpart primary ext4 125GB 100% \
#        set 1 boot on \
#   || die


## HDD formating (-F: overwrite if necessary)

# root "/" will be the preexistent SDD /dev/sdc3 (125GB) 
mkfs.ext4 -F /dev/sdc3 || die
# "/home"  will be the preexistent HDD /dev/sda3 (33.3GB)
# mkfs.ext4 -F /dev/sda3 || die
# "/home"  will be the preexistent HDD /dev/sdb1 (1,8TB)
lsblk
read -p "==> Do you want to partition HDD /dev/sdb?[y/N]" answer
if [[ "${answer:-N}" =~ ^([yY])$ ]]; then
  printf " --> Partitioning /dev/sdb\n\n"
  parted -s -a optimal /dev/sdb \
	 mklabel msdos \
	 mkpart primary ext4 0% 100% || die
  printf " --> Formatting /dev/sdb\n\n"
  mkfs.ext4 -F /dev/sdb1 || die
else
  unset answer
  read -p "==> Do you want to format /dev/sdb1 (aka /home)?[y/N]" answer
  if [[ "${answer:-N}" =~ ^([yY])$ ]]; then
    printf " --> Formatting /dev/sdb\n\n"
    mkfs.ext4 -F /dev/sdb1 || die
  fi
fi
unset answer


## HDD mounting

# root /
mount /dev/sdc3 /mnt || die
# /home
mkdir -p /mnt/home || die
mount /dev/sdb1 /mnt/home || die
# mount /dev/sda3 /mnt/home || die

# show result
(lsblk && sleep 3)
# if previous /home dot-files exists, ask to delete them
# if find /mnt/home/"${user_name}" -maxdepth 1 -type f -name ".*"; then
if find /mnt/home/"${user_name}" -maxdepth 1 -type f -name ".*"; then
  printf "\n"
  read -p "==> Dir /home detected. Delete previous configuration files?[Y/n]" answer
  if [[ "${answer:-Y}" =~ ^([yY])$ ]]; then
    printf " --> Deleting 'dot-files directories' in '/home' \n\n"
    find /mnt/home/"${user_name}"/ -maxdepth 1 -type d -name ".*" \
      | xargs rm -rf \
      || die
    printf " --> Deleting 'dot-files' in '/home' \n\n"
    find /mnt/home/"${user_name}" -maxdepth 1 -type f -name ".*" \
      | xargs rm -rf \
      || die
    rm -rf /mnt/home/"${user_name}"/.bash-git-prompt
    printf " --> Deleting 'directories' in '/home' \n\n"
    find /mnt/home/"${user_name}"/*/ -maxdepth 0 -type d \
     -not -path "/mnt/home/${user_name}/Documents/*" \
     -not -path "/mnt/home/${user_name}/Pictures/*" \
     -not -path "/mnt/home/${user_name}/Videos/*" \
      | xargs rm -rf \
      || die
    printf " --> Deleting 'folders' in '/' \n\n"
    rm -rf \
       /mnt/{bin,boot,dev,etc,lib,lib64,opt,run,sbin,srv,tmp,usr,var} \
      || die
  fi
fi

### REQUIREMENTS BEFORE SYSTEM PACKAGES INSTALLATION

## record packages installation time
SECONDS=0

## update keyring
pacman -Syy --noconfirm archlinux-keyring || die


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
if lspci -k | grep -e "3D.*NVIDIA" &> /dev/null; then
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
  # programming
  Packages+=('python-pip')
  # text editor
  Packages+=('libreoffice-fresh' 'libreoffice-fresh-de')
  Packages+=('libreoffice-fresh-en-gb' 'libreoffice-fresh-es')
  # text edition - latex support
  # read -p "LATEX download take time. Install it anyway?[y/N]" response
  # [[ "${response}" =~ ^[yY]$ ]] \
  #     && Packages+=('texlive-core' 'texlive-latexextra')
  Packages+=('texlive-core' 'texlive-latexextra')
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
  Packages+=("${DesktopPkg[@]}")
  printf "%s\n" "${Packages[@]}" | grep terminal
  read -p "==> Packages to install. Continue?[Y/n]" answer
  if [[ "${answer:-Y}" =~ ^([nN])$ ]]; then die; fi
fi

## System Packages Installation
pacstrap /mnt --needed --noconfirm "${Packages[@]}" || die


### GENERATE FILE SYSTEM TABLE

genfstab -L /mnt >> /mnt/etc/fstab || die

# if present, add aditional hardware to fstab 
# if [[ "${MACHINE}" == 'Real' ]]; then
#   # desired result:
#   #  LABEL=xxx /dir ext4 rw,nosuid,nodev,user_id=0,group_id=0,allow_other,blksize=4096 0 0
#   # code example:
#   #  mount --types ext4 /dev/sdxY /dir -o noatime,nodev,nosuid
#   mount_drive="$(lsblk -f | awk '/lack/{ print $0 }')" || die
#   if [[ -n "${mount_drive}" ]]; then
#     tmp_array=( $mount_drive )
#     my_drive="${tmp_array[0]:2}" || die
#     my_fs="${tmp_array[1]}" || die
#     my_label="${tmp_array[2]}" || die
#     my_UUID="${tmp_array[3]}" || die
#     my_path=/run/media/"${user_name}"/"${my_label}" || die
#       echo "# ${my_UUID}
# /dev/${my_drive:2} 									${my_path} 		${my_fs} 	uid=1000,gid=1000,umask=0022,fmask=133 	0 0
# " >> /etc/fstab || die
#       unset my_path || die
#       unset mount_drive || die
#     fi
# fi


### SCRIPTING INSIDE CHROOT

# copy and run script2.sh to configure the new Arch Linux system
cp ./script2.sh /mnt/home || die
arch-chroot /mnt bash /home/script2.sh || die
# remove script2.sh after finish
rm /mnt/home/script2.sh || die
# python support for virtualenv
# arch-chroot -u "${user_name}" /mnt bash -c "HOME=/home/${user_name};\
# mkdir -p $HOME/.virtualenvs && cd $HOME/.virtualenvs;\
# pip install virtualenv virtualenvwrapper" || die


### DOTFILES

# copy dotfiles to new system
cp ./dotfiles/.[a-z]* /mnt/home/"${user_name}" || die
# create the folder Project in $HOME
my_path=/mnt/home/"${user_name}"/Projects/archlinux
mkdir -p "${my_path}" || die
# backup archlinux repo inside ~/Projects folder
cp -r . "${my_path}" || die
# correct git branch in archlinux repo
# arch-chroot /mnt bash -c "cd $HOME/Projects/dot-emacs && git checkout ssd" || die
# backup the scripts used during arch linux installation
my_path=/mnt/home/"${user_name}"/Projects/archlinux_install_report
mkdir -p "${my_path}" || die
cp ./script[1-2].sh "${my_path}" || die
# copy script3 only if user selected to install a desktop
if [[ "${install_desktop}" =~ ^([yY])$ ]]; then
  cp ./desktop/"${system_desktop}"/script3.sh "${my_path}" \
    || die
fi
duration=$SECONDS || die
echo "user_name=${user_name}
MACHINE=${MACHINE}
script1_time_seconds=${duration}
" > "${my_path}"/installation_report || die
chmod +x "${my_path}"/installation_report || die
unset my_path || die


### BIN SCRIPTS

if [[ "${install_desktop}" =~ ^([yY])$ ]]; then
  my_path=/mnt/home/"${user_name}"/bin
  mkdir -p "${my_path}" || die
  cp ./desktop/scripts-shared/* "${my_path}" || die
fi

# correct user permissions
arch-chroot /mnt bash -c "\
chown -R ${user_name}:${user_name} /home/${user_name}/.[a-z]*;\
chown -R ${user_name}:${user_name} /home/${user_name}/[a-zA-Z]*;\
chown -R ${user_name}:${user_name} /home/${user_name}/Down*/*;" || die


### UNMOUNT EVERYTHING AND REBOOT
read -p "$0 install succeded (${duration} seconds)! umount '/mnt' and reboot?[Y/n]" response
[[ "${response:-Y}" =~ ^([yY])$ ]] \
  && umount -R /mnt | reboot now


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
