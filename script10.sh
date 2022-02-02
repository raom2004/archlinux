#!/bin/bash
#
# ./script1.sh is a script to install Arch Linux amd configure a desktop
#
# Summary:
# * This script contain all the commands required to prepare a system
#   for a new Arch Linux installation.
# * This script also call the script2.sh to execute all the commands
#   that must be run inside the new Arch Linux install, by arch-chroot.


### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING ###################

# shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


### FUNCTION DECLARATION

nullify() {
  "$@" >& /dev/null
  return 0
}
ignore_error() {
  "$@" 2>/dev/null
  return 0
}


### error handling

out() { printf "$1 $2\n" "${@:3}"; }
error() { out "==> ERROR:" "$@"; } >&2
warning() { out "==> WARNING:" "$@"; } >&2
msg() { out "==>" "$@"; }
msg2() { out "  ->" "$@";}
die() { error "$@"; exit 1; }


### Declare variables to use in script2.sh. Hide passwords by -sp option.

read -p "Enter hostname: " host_name
read -sp "Enter ROOT password: " root_password
read -p "Enter NEW user: " user_name
read -sp "Enter NEW user PASSWORD: " user_password
user_shell=/bin/zsh
hdd_partitioning=/dev/sda
# make these variables available for script2.sh
export host_name
export root_password
export user_name
export user_password
export user_shell


### SET TIME AND SYNCHRONIZE SYSTEM CLOCK
timedatectl set-ntp true


### HDD PARTITIONING (BIOS/MBR)
# umount if previously mounted /mnt
mount | grep -q /mnt && umount -R "$_" || msg "no previous /mnt detected"

fi
msg "partitioning %s" "${hdd_partitioning}"
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

## check if actual system run inside virtual (VBox) or Real Machine
pacman -S --noconfirm dmidecode \
    || die 'can not install dmidecode required to identify actual system'
machine="$(dmidecode -s system-manufacturer)"
[[ "$machine" == "innotek GmbH" ]] && MACHINE='VBox' || MACHINE='Real'
# if arch linux install is inside VirtualBox add guest utils package
[[ "${MACHINE}" == "VBox" ]] && Packages=('virtualbox-guest-utils')

## Get Current Boot Mode:
if ! ls /sys/firmware/efi/efivars 2>/dev/null; then
  boot_mode='BIOS'
else
  boot_mode='UEFI'
fi


### SYSTEM PACKAGES INSTALLATION

## (2/3) Essential Package List:
Packages+=('base' 'base-devel' 'linux')
# shell	
Packages+=('zsh')
# tools
Packages+=('sudo' 'git' 'wget')
# mounting tools (required for filemanagers)
Packages+=('gvfs')
# editors
Packages+=('vim')
# network
Packages+=('dhcpcd')
# wifi
Packages+=('networkmanager')
# boot loader
Packages+=('grub' 'os-prober')
# UEFI boot support
Packages+=('efibootmgr')
# multi-OS support
Packages+=('usbutils' 'dosfstools' 'ntfs-3g' 'amd-ucode' 'intel-ucode')
# backup
Packages+=('rsync')
# glyphs support
Packages+=('ttf-{hanazono,font-awesome,ubuntu-font-family}' 'noto-fonts')
# graphical user interface
#  * xorg display server (wayland has not support nvidia CUDA yet)
Packages+=('xorg-{server,xrandr}' 'xterm')
#  * NVIDIA display driver
if lspci -k | grep -e "3D.*NVIDIA" &>/dev/null; then
    [[ "${Packages[*]}" =~ 'linux-lts' ]] && Packages+=('nvidia-lts')
    [[ "${Packages[*]}" =~ 'linux' ]] && Packages+=('nvidia')
fi
#  * desktop environment
Packages+=('xfce4')
Packages+=('xfce4-{pulseaudio-plugin,screenshooter}')
Packages+=('pavucontrol' 'pavucontrol-qt')
Packages+=('papirus-icon-theme')

## (3/3) INSTALLING PACKAGES
pacstrap /mnt "$(echo "${!Packages[@]}")" \
    || die 'Pacstrap can not install the packages'


### generate file system table
genfstab -L /mnt >> /mnt/etc/fstab || die 'can not generate $_'


## scripting inside chroot by copying and running script2.sh
cp ./script20.sh /mnt/home || die "can not copy script20.sh to $_"
arch-chroot /mnt bash /home/script20.sh || die "can not run arch-root $_"
rm /mnt/home/script20.sh || die "can not remove $_"


## DESKTOP CUSTOMIZATION ON STARTUP (running script3.sh) 
cp ./script7.sh /mnt/home/script3.sh || die "can not copy $_"
chmod +x /mnt/home/script3.sh || die "can not set executable $_"


## DOTFILES
# copy files to new system
cp ./dotfiles/.[a-z]* /mnt/home/"${user_name}"
# correct user permissions
arch-chroot /mnt bash -c "chown -R ${user_name}:${user_name} /home/${user_name}/.[a-z]*" || die 'can correct user permissions'


## In the end unmount everything and exiting
read -p "install successful! umount /mnt and exit?[y/N]" response
[[ ! "${response}" =~ ^[yY]$ ]] && umount -R /mnt | shutdown now
