#!/bin/bash
#
# script1.h: bash script for install archlinux with support for BIOS/MBR 

# Dependencies:
#  built-in files (see above)


### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING ###################

# shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


### SET WORKING DIRECTORY

cd "$(dirname "${BASH_SOURCE}")" # Set working directory


### DEPENDENCIES

source ./include/ANSI_escape_colors
source ./include/functions


### VARIABLE DECLARATION

installer_version=v0.8.1
script_start_time="$(date +%s)"	# record runtime of the archlinux install
log=archlinux_install_script.log


### FUNCTION DECLARATION

########################################
# Purpose: display usage of this archlinux installer bash script 
# Arguments: global variable "installer_version"
########################################

function prerequirements {
  ##  Verify Internet Connection
  if ! ping -c 1 -q google.com >&/dev/null; then
    echo "Internet required. Cancelling install.."
    exit 0
  fi
  ## Verify Root Priviledges
  ROOT_UID=0  # Root has $UID 0.
  if [[ ! "$UID" -eq "$ROOT_UID" ]]; then
    echo "ROOT priviledges required. Cancelling install.."
    exit 0
  fi
}


########################################
# Purpose: display usage of this archlinux installer bash script 
# Arguments: global variable "installer_version"
########################################
function display_usage
{
  printf "
ARCHLINUX installer Version %s
Summary: A bash script that automates the archlinux install. 
  * It follows the archlinux official guidelines.
  * The installation supports internal HDD or USB/SD removable devices.
  * It supports the partitioning layouts BIOS/MBR, BIOS/GPT. 
  * It is designed as a template for easily edition and customization.

Usage: ${0##*/} [options]
  -h|--help         display usage

Example:
  ${Green}$ sh ${0}${NC} 

The archlinux install will ask for the variables, on demand:
  * A block device for install linux on, e.g. \"/dev/sdX\"
  * A name for the host
  * A root password
  * A new user name, and password
  * A shell for the user, options: \"bash\", \"zsh\"
  * A language (e.g.: en, de, fr) to show keyboard keymaps available

The system locale is set to american english (LANG=en_EN.UTF-8), but:
  * Can be overrided per user session, editing: ~/.config/locale.conf

The archlinux installer include other advanced options, such as:
  * Activate automatic logging on tty1 (available for testing purposes).
  * Create a DUPLICATE OF THE SYSTEM, with dd, for RECOVERY and TESTING.

Why this installer include an option to DUPLICATE THE SYSTEM?
  Well, archlinux maintenance require packages and kernel upgrades
  that eventually could break the system. For this reason, have a
  booteable duplicate of the system its advantageus for: test upgrades
  before apply them in the main system or easily recover the system
  after an important failure.

How this installer will partition the disk?
The standard install WITHOUT recovery, will partition the disk, such as:
  * A /boot partition, dedicated for the bootloader (GRUB) for BIOS/GPT. 
  * A /root partition, for the archlinux system.

The install WITH recovery partition, will partition the disk, such as: 
  * A /     partition, containing the original archlinux system.
  * A /     partition, a duplicate for upgrade testing or recovery.
  * A /boot partition, dedicated for the bootloader for BIOS/GPT or UEFI.
  * A /home partition (optional, to share documents in both systems).

IMPORTANT: System Locale
  * This installer will set the system locale to american english, e.g.:
    # localectl set-locale LANG=en_EN.UTF-8
  * After the install, you can overrride this system locale by editing:
    $XDG_CONFIG_HOME/locale.conf (usually ~/.config/locale.conf)
  
" "${installer_version}"
  exit 0
}


########################################
# Purpose: customize the error messages
# Arguments: positional arguments
########################################
function err
{
  echo "[$(date +'%Y-%m-%dT%H:%M:$S%z')]: $*" >&2
}


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
  printf "List of block devices (lsblk):\n%s\n\n" "$(lsblk)"
  printf "Between the block devices detailed bellow,\n"
  printf "choose a device to install archlinux on:\n"
  
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


function main {

  ### GET HELP

  # display usage when user provide the help tag '--help | -h' 
  (( "$#" == 1 )) && [[ "$1" =~ (--help)|(-h) ]] && display_usage


  ### GET SYSTEM INFORMATION DURING ARCHLINUX INSTALL

  # Get Current Machine: Virtualbox (VBox) vs REAL
  pacman -Sy --noconfirm --needed dmidecode
  check="$(dmidecode -s system-manufacturer)"
  [[ "${check}" == "innotek GmbH" ]] && machine='VBox' || machine='REAL'

  # Get Current Boot Mode:
  if ! ls /sys/firmware/efi/efivars 2>/dev/null; then
    boot_mode='BIOS'
  else
    boot_mode='UEFI'
  fi

  ### CREATE LOG FILE WITH SYSTEM INFO
  echo "Archlinux installer version: ${installer_version}" > "${log}"
  echo "Start time: ${script_start_time}" >> "${log}"
  echo "Machine: ${machine}" >> "${log}"
  echo "Boot Mode: ${boot_mode}" >> "${log}"

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
  [[ ! "${user_shell}" =~ ^([b][a]|[z])(sh)$ ]] && err >> "${log}"
  read -p "Enter SHELL KEYMAP (e.g. en, de, fr) " shell_keymap
  [[ ! "${shell_keymap}" =~ ^([a-z][a-z])$ ]] && err >> "${log}"
  read -p "Do you want to AUTOLOG IN TTY1 at startup?[y/N]" autolog_tty
  [[ ! "${autolog_tty}" =~ ^([yY]|[nN])$ ]] && err >> "${log}"

  # ask user to create a recovery partition and MBR
  read -p "Create a recovery partition?[y/N]" recovery_partition
  [[ ! "${recovery_partition}" =~ ^([yY]|[nN])$ ]] && err >> "${log}"


  ### SET TIME AND SYNCHRONIZE SYSTEM CLOCK

  timedatectl set-ntp true


  ### DISK PARTITIONING, FORMATING AND MOUNTING

  ## - 1 - Partitioning a HDD, NO Partition Recovery
  if [[ ! "${recovery_partition}" =~ ^([yY][eE][sS]|[yY])$ ]]; then

    ## General Disk Partitioning Scheme: 3 partitions in 8GB
    #  /boot (/dev/sdx1, 300MB)
    #  /home (/dev/sdx2, 3.7GB)
    #  /root (/dev/sdx3, 4GB remaining space)

    ## Partitioning disk with MBR table:
    parted -s "${target_device}" mklabel msdos
    parted -s -a optimal "${target_device}" mkpart primary ext2 0% 300MB
    parted -s "${target_device}" set 1 boot on
    parted -s -a optimal "${target_device}" mkpart primary ext4 300MB 4GB
    parted -s -a optimal "${target_device}" mkpart primary ext4 4GB 8GB

    ## Formating partitions (-F=overwrite if necessary)
    mkfs.ext2 -F "${target_device}1"
    mkfs.ext4 -F "${target_device}2"
    mkfs.ext4 -F "${target_device}3"
    
    ## Mounting partitions
    # partition "/"
    mount "${target_device}3" /mnt
    # partition "/boot"
    mkdir /mnt/{boot,home}
    mount "${target_device}1" /mnt/boot
    mount "${target_device}2" /mnt/home
  fi

  ## - 2 - Partitioning a HDD, WITH Partition Recovery
  if [[ "${recovery_partition}" =~ ^([yY][eE][sS]|[yY])$ ]]; then

    ## General Disk Partitioning Scheme: 4 partitions
    #  /boot (/dev/sdx1, 300MB, shared between /root directories)
    #  /home (/dev/sdx2, 3.7GB, shared between /root directories)
    #  /root (/dev/sdx3, 4GB, original)
    #  /root (/dev/sdx4, 4GB, duplicate for recovery or testing purposes)

    ## Partitioning disk:
    parted -s "${target_device}" mklabel msdos # MBR partition table
    parted -s -a optimal "${target_device}" mkpart primary ext2 0% 300MB
    parted -s -a optimal "${target_device}" mkpart primary ext4 300MB 4GB
    parted -s -a optimal "${target_device}" mkpart primary ext4 4GB 8GB
    parted -s -a optimal "${target_device}" mkpart primary ext4 8GB 12GB

    ## Formating partitions (-F=overwrite if necessary)
    mkfs.ext2 -F "${target_device}1"
    mkfs.ext4 -F "${target_device}2"
    mkfs.ext4 -F "${target_device}3"
    mkfs.ext4 -F "${target_device}4"

    ## Mounting partitions
    # root partition "/" 
    mount "${target_device}3" /mnt
    # discrete partitions
    mkdir /mnt/{boot,home}
    mount "${target_device}1" /mnt/boot
    mount "${target_device}2" /mnt/home
  fi


  ### ARCHLINUX PACKAGE INSTALLATION

  ## Important: update package manager keyring
  pacman -Syy --noconfirm archlinux-keyring

  ## install system elementary packages
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
  # system backup	
  [[ "${recovery_partition}" =~  ^([yY])$ ]] && pacstrap /mnt rsync


  ## generate fstab
  genfstab -L /mnt >> /mnt/etc/fstab


  ## copy chroot-script.sh to new system
  cp "$PWD"/chroot-script.sh /mnt/home \
    || cp arch/chroot-script.sh /mnt/home 


  ## change root and run chroot-script.sh
  arch-chroot /mnt sh /home/chroot-script.sh \
	      "${target_device}" \
	      "${host_name}" \
	      "${root_password}" \
	      "${user_name}" \
	      "${user_password}" \
	      "${user_shell}" \
	      "${shell_keymap}" \
	      "${autolog_tty}" \
	      "${recovery_partition}"

  ## config boot loader GRUB
  arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

  ## remove script
  #rm /mnt/home/script2.sh

  
  ### SYSTEM RECOVERY:

  # source:
  # https://wiki.archlinux.org/title/Install_Arch_Linux_from_existing_Linux

  ## mounting device
  duplicate=/mnt/install
  mkdir -p "${duplicate}"
  mount "${target_device}4" "${duplicate}"


  ## Option 1: create a new archlinux installation 
  
  # ## avoid redownloading all the packages 
  # pacstrap -c "${duplicate}" --cachedir /mnt/var/cache/pacman/pkg \
  # 	   base base-devel linux \
  # 	   vim nano \
  # 	   zsh sudo git wget \
  # 	   gvfs \
  # 	   dhcpcd \
  # 	   networkmanager \
  # 	   grub os-prober

  ## configure grub automatically
  # arch-chroot "${duplicate}" grub-mkconfig -o /boot/grub/grub.cfg

  ## sidable lvmetad (maybe required)
    # sed -i 's%use_lvmetad = 0%use_lvmetad = 1%' \
      # "${duplicate}/etc/lvm/lvm.conf""
  

  ### Option 2: create a copy of an existen archlinux installation

  ## full system backup
  arch-chroot /mnt rsync -aAXHv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","/${duplicate##*/}"} / "/${duplicate##*/}"

  ## config boot loader GRUB automatically
  arch-chroot "${duplicate}" grub-mkconfig -o /boot/grub/grub.cfg || arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

  ## generate a new machine-id in the next boot
  rm -rf "${duplicate}/etc/machine-id"
  
  ## copy script2.sh to new system
  # cp "$PWD"/script2.sh /mnt/home || cp arch/script2.sh /mnt/home 
  
  ## make pacman use the package database downloaded in the new system
  # sed 's%#\[testing\]%[custom]\nSigLevel = Optional TrustAll\nServer = file:///mnt/var/cache/pacman/pkg\n%' /etc/pacman.conf

  
  ## generate a log file with installation runtime
  script_end_time="$(date +%s)"
  runtime="$((${script_end_time}-${script_start_time}))"
  printf "Archlinux install script
# Start time: ${script_start_time}
# End Time: ${script_end_time}
#  Install Runtime : ${runtime}
" >> "${log}"

  ## Backup of MBR
  backup_dir=/mnt/home/"${user_name}"/.backup
  mkdir -p "${backup_dir}"
  # Backup only the Partition Table (recommended)  
  sfdisk -d "${target_device}" > "${backup_dir}"/sfdisk_ptable
  # Backup entire MBR (MBR + Partition Table)
  dd if="${target_device}" of="${backup_dir}"/mbr_backup bs=512 count=1


  mv "${log}" "${backup_dir}/${log}"


  ## Restoring backup of MBR
  # Restoring only the Partion Table (usually only this is necessary)
  # sudo sfdisk /dev/sda < sfdisk_sda
  # Restoring only the MBR (without changing the Partition Table)
  # sudo dd if=mbr_sda of=/dev/sda bs=446 count=1
  # Restoring only the Partition Table (without changing the MBR)
  # sudo dd if=mbr_sda of=/dev/sda bs=1 count=64 skip=446 seek=446
  # Restoring the MBR + Partition Table
  # sudo dd if=mbr_sda of="${target_device}" bs=512 count=1


  ## umount archlinux new system partition /mnt 
  umount -R /mnt
  # [[ -d /mnt2 ]] && umount /mnt2


  ## restore bash history
  set -o history 

  shutdown now
}

main "$@"


# Local Variables:
# sh-basic-offset: 2
# End:
