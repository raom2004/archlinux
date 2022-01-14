#!/bin/bash
#
# script1.sh: bash script for install archlinux with support for BIOS/MBR 

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


### GLOBAL VARIABLE DECLARATION

script_start_time="$(date +%s)"	# record runtime of the archlinux install
log=archlinux_install_script.log


### FUNCTION DECLARATION

########################################
# Purpose: display usage of this archlinux installer bash script 
# Arguments: none
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
# Arguments: none
########################################
function display_usage
{
  printf "
ARCHLINUX installer
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
  * Create a booteable backup, with rsync, for RECOVERY and TESTING.

Why this installer include an option for a booteable backup?
  Well, archlinux maintenance require packages and kernel upgrades
  that eventually could break the system. For this reason, have a
  booteable backup its advantageus for: test upgrades before apply
  them in the main system or easily recover the system after an
  important failure.

How this installer will partition the disk?
The standard install WITHOUT basckup, will partition the disk, such as:
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
  
"
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
  echo "Archlinux installer" > "${log}"
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

  # log parameters
  set +o xtrace			# please do not show passwords
  printf "\nEnter ${Green}HOST name${NC}:"
  read host_name
  printf "\n\nEnter ${Green}ROOT PASSWORD${NC}: "
  read -s root_password
  printf "\n\nEnter ${Green}USER name${NC}: "
  read user_name
  printf "\n\nEnter ${Green}USER PASSWORD${NC}: "
  read -s user_password
  printf "\n\n"
  set -o xtrace			# trace & expand what gets executed
  
  # parameters to select only if machine is real
  if [[ "${machine}" == 'REAL' ]]; then
    read -p "Enter USER SHELL (e.g. bash, zsh) " user_shell
    [[ ! "${user_shell}" =~ ^([b][a]|[z])(sh)$ ]] && err >> "${log}"
    read -p "Enter SHELL KEYMAP (e.g. en, de, fr) " shell_keymap
    [[ ! "${shell_keymap}" =~ ^([a-z][a-z])$ ]] && err >> "${log}"
    read -p "Do you want to AUTOLOG IN TTY1 at startup?[y/N]" autolog_tty
    [[ ! "${autolog_tty}" =~ ^([yY]|[nN])$ ]] && err >> "${log}"
    # ask user to create a recovery partition and MBR
    read -p "Create a backup partition?[y/N]" backup_partition
    [[ ! "${backup_partition}" =~ ^([yY]|[nN])$ ]] && err >> "${log}"
  fi

  # if virtual machine set commond variables
  if [[ "${machine}" == 'VBox' ]]; then
    user_shell="bash"
    shell_keymap="es"
    autolog_tty="y"
    backup_partition="N"
  fi


  ### SET TIME AND SYNCHRONIZE SYSTEM CLOCK

  timedatectl set-ntp true


  ### DISK PARTITIONING, FORMATING AND MOUNTING

  disk_usage=50%

  if [[ ${boot_mode} == "BIOS" ]]; then
    printf "BIOS detected! you can select a GPT or MBR partition table:\n"
    select OPTION in MBR GPT; do
      case ${OPTION} in
	MBR)
	  ## HDD partitioning (BIOS/MBR)
	  parted -s "${target_device}" mklabel msdos
	  parted -s -a optimal "${target_device}" mkpart primary ext4 0% "${disk_usage}"
	  parted -s "${target_device}" set 1 boot on
	  
	  ## HDD formating (-F: overwrite if necessary)
	  mkfs.ext4 -F "${target_device}1"

	  ## HDD mounting
	  mount "${target_device}1" /mnt
	  break
	  ;;
	GPT)
	  ## HDD partitioning (BIOS/GPT)
	  parted -s "${target_device}" mklabel gpt
	  parted -s -a optimal "${target_device}" mkpart primary ext2 0% 2MiB
	  parted -s "${target_device}" set 1 bios_grub on
	  parted -s -a optimal "${target_device}" mkpart primary ext4 2MiB "${disk_usage}"
	  
	  ## HDD formating (-F: overwrite if necessary)
	  mkfs.ext4 -F "${target_device}2"
	  
	  ## HDD mounting
	  mount "${target_device}2" /mnt
	  break
	  ;;
      esac
    done
  fi

  if [[ ${boot_mode} == "UEFI" ]]; then
    ## HDD partitioning (UEFI/GPT)
    parted -s "${target_device}" mklabel gpt
    parted -s -a optimal "${target_device}" mkpart primary 0% 512MiB
    parted -s "${target_device}" set 1 esp on
    parted -s -a optimal "${target_device}" mkpart primary 512MiB "${disk_usage}"

    ## HDD formating (-F: overwrite if necessary)
    mkfs.fat -F32 "${target_device}1"
    mkfs.ext4 -F "${target_device}2"

    ## HDD mounting
    mount "${target_device}2" /mnt
    mkdir -p /mnt/boot/efi
    mount "${target_device}1" /mnt/boot/efi
  fi


  ### ARCHLINUX PACKAGE INSTALLATION

  ## Important: update package manager keyring
  pacman -Syy --noconfirm archlinux-keyring

  ## install system elementary packages
  # essential packages
  pacstrap /mnt base base-devel linux 
  # packages for hardware functionallity
  # [[ "${machine}" == 'REAL' ]] && pacstrap /mnt linux-firmware
  # editors
  pacstrap /mnt vim nano
  # system shell	
  # pacstrap /mnt zsh
  # system tools	
  pacstrap /mnt sudo git wget
  # system mounting tools
  # pacstrap /mnt gvfs
  # network
  pacstrap /mnt dhcpcd
  # wifi
  pacstrap /mnt networkmanager
  # multi-OS support packages
  # pacstrap /mnt usbutils dosfstools ntfs-3g amd-ucode intel-ucode
  # system backup	
  # pacstrap /mnt rsync
  # inmprove glyphs support
  # pacstrap /mnt ttf-{hanazono,font-awesome,ubuntu-font-family}
  # boot loader	
  pacstrap /mnt grub #os-prober
  ## package required for GRUB to boot in UEFI mode
  if [[ ${boot_mode} == "UEFI" ]]; then
    pacstrap /mnt efibootmgr	 
  fi

  
  ## generate fstab
  genfstab -L /mnt >> /mnt/etc/fstab


  ## copy chroot-script.sh to new system
  cp "$PWD"/script2.sh /mnt/home \
    || cp arch/script2.sh /mnt/home 

  ## change root and run chroot-script.sh
  set +o xtrace			# avoid to show passwords 
  arch-chroot /mnt sh /home/script2.sh \
	      "${target_device}" \
	      "${host_name}" \
	      "${root_password}" \
	      "${user_name}" \
	      "${user_password}" \
	      "${user_shell}" \
	      "${shell_keymap}" \
	      "${autolog_tty}" 
  set -o xtrace			# trace & expand what gets executed

  
  ## config boot loader GRUB
  arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

  
  ## remove script
  #rm /mnt/home/script2.sh

  if [[ "${backup_partition}" =~  ^([yY])$ ]]; then

    ## SYSTEM RECOVERY: Make a copy of an existen archlinux installation
    # source:
    # https://wiki.archlinux.org/title/Install_Arch_Linux_from_existing_Linux

    ## full system backup
    arch-chroot /mnt rsync -aAXHv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","/recovery"} / /recovery
    
    ## update fstab
    genfstab -L /mnt/recovery >> /mnt/recovery/etc/fstab
    
    ## config boot loader GRUB automatically
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

    ## generate a new machine-id in the next boot
    rm -rf /mnt/recovery/etc/machine-id
    
    ## copy script2.sh to new system
    # cp "$PWD"/script2.sh /mnt/home || cp arch/script2.sh /mnt/home 
    
    ## make pacman use the package database downloaded in the new system
    # sed 's%#\[testing\]%[custom]\nSigLevel = Optional TrustAll\nServer = file:///mnt/var/cache/pacman/pkg\n%' /etc/pacman.conf

  fi
  
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
  # umount -R /mnt
  # [[ -d /mnt2 ]] && umount /mnt2


  ## restore bash history
  set -o history 

  # shutdown now

  printf "${Green}Installation successful${NC}\n"

}

main "$@"


# Local Variables:
# sh-basic-offset: 2
# End:
