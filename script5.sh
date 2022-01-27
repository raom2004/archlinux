#!/bin/bash
#
# script5.sh install archlinux with root & user accounts by arch-chroot  


### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING ###################

# shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


########################################
# Purpose: display usage of this archlinux installer bash script 
# Arguments: none
########################################
function display_usage
{
  printf "
A bash script which automate Arch Linux install using chroot. 

Usage: ${0##*/} [options]
  -h|--help         display usage
  -e|--example      set Arch Linux required variables automatically:
		       * Host Name = \"myhost\"
		       * Root Password = \"rootpassword\"
		       * User Name = \"myuser\"
		       * User Password = \"userpassword\"

Example:
  ${Green}$ bash ${0}${NC} 

The install without -e option will ask for variables on demand, such as:
  * A host name
  * A root password
  * A new user name and password

LANGUAGE:
  * The standard system locale is set to america english, e.g:
    # echo \"LANG=en_US.UTF-8\" > /etc/vconsole.conf
  * The script habilitate multiple languages with UTF-8 in locale, e.g.:
    de_DE, en_US, en_GB, es_ES, fr_FR, ru_RU, zn_CN
  * The standard confirguration can be overrided by per user session, e.g.:
    # echo \"LANG=de_DE.UTF-8\" > ~/.config/locale.conf  
  * Important: some desktops can override such per user configuration.
"
}


set +o xtrace      # please do not show sensitive data

## restart /mnt if was previously mount
mount | grep -q /mnt && umount -R /mnt

## use positional arguments or declare variables hiding passwords by -sp option.
case "${1:-*}" in
    --example|-e)
	host_name="myhost"
	root_password="rootpassword"
	user_name="myuser"
	user_password="userpassword"
	;;
    --help|-h)
	display_usage
	exit 0
	;;
    *)
	read -p "Enter hostname: " host_name
	read -sp "Enter ROOT password: " root_password
	read -p "Enter NEW user: " user_name
	read -sp "Enter NEW user PASSWORD: " user_password
	;;
esac

# make these variables available for script2.sh
export host_name
export root_password
export user_name
export user_password

set -o xtrace      # trace & expand what gets executed

## set time and synchronize system clock
timedatectl set-ntp true


## HDD partitioning (BIOS/MBR)
parted -s /dev/sda \
       mklabel msdos \
       mkpart primary ext2 0% 2% \
       set 1 boot on \
       mkpart primary ext4 2% 100%
## HDD partitions formating (-F=overwrite if necessary) & mounting
# root partition "/"
mkfs.ext4 -F /dev/sda2
mount /dev/sda2 /mnt
# boot partition "/boot"
mkfs.ext2 -F /dev/sda1
mkdir /mnt/boot && mount /dev/sda1 /mnt/boot


## Install packages
# Important: update package manager keyring before install packages
pacman -Syy --noconfirm archlinux-keyring
# install minimum system packages (with support for wifi and ethernet)
pacstrap /mnt base base-devel linux \
	 zsh sudo vim git wget \
	 dhcpcd \
	 networkmanager \
	 grub
# install display server
pacstrap /mnt xorg-{server,xrandr} xterm
# install desktop packages (just xfce4)
pacstrap /mnt xfce4 \
	 xfce4-{pulseaudio-plugin,screenshooter} \
	 pavucontrol pavucontrol-qt \
	 papirus-icon-theme
# install virtual machine support (VirtualBox) if neccesary
pacman -Sy --noconfirm dmidecode
my_system="$(sudo dmidecode -s system-manufacturer)"
if [[ "${my_system}" == "innotek GmbH" ]]; then
  pacstrap /mnt virtualbox-guest-utils
fi
# generate file system table (required for boot loader)
genfstab -L /mnt >> /mnt/etc/fstab


# scripting inside chroot from outside: script2.sh
# copy script2.sh to new system
cp ./script6.sh /mnt/home
cp ./script7.sh /mnt/home/"${user_name}"
# run script2.sh commands inside chroot
arch-chroot /mnt bash /home/script6.sh
# remove script2.sh after completed
rm /mnt/home/script6.sh

echo "installation finished succesfully"