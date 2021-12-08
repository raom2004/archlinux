#!/bin/bash
#
# script2.sh: designed to run inside script1.sh chroot into new system   


### BASH SCRIPT1.SH OPTIONS ##########################################


## options for DEBUGGING

set -o errtrace # inherit any trap on ERROR
set -o functrace # inherit any trap on DEBUG and RETURN
set -o errexit  # EXIT if script command fails
set -o nounset  # EXIT if script try to use undeclared variables
set -o pipefail # CATCH failed piped commands
set -o xtrace   # trace & expand what gets executed (useful for debugging)


## variable declaration

host_name="${1}"
root_password="${2}"
user_name="${3}"
user_password="${4}"
mountpoint="${5}"


## Time Configuration

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc


## Language Configuration

sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/#en_GB.UTF-8/en_GB.UTF-8/' /etc/locale.gen
sed -i 's/#en_DK.UTF-8/en_DK.UTF-8/' /etc/locale.gen
sed -i 's/#es_ES.UTF-8/es_ES.UTF-8/' /etc/locale.gen
sed -i 's/#de_DE.UTF-8/de_DE.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8'              >  /etc/locale.conf
echo 'LANGUAGE=en_US:en_GB:en' >> /etc/locale.conf
echo 'LC_COLLATE=C'                  >> /etc/locale.conf
echo 'LC_MESSAGES=en_US.UTF-8'       >> /etc/locale.conf
echo 'LC_TIME=en_DK.UTF-8'           >> /etc/locale.conf


## Keyboard Configuration

echo 'KEYMAP=es' > /etc/vconsole.conf
# localectl set-keymap --no-convert es


## Network Configuration
echo "${host_name}" > /etc/hostname
bash -c "echo \"127.0.0.1	localhost
::1		localhost
127.0.1.1	${host_name}.localdomain	${host_name}\" \
 >> /etc/hosts"


## TODO: Western Digital firmware modules pending: aic94xx wd719x xhci_pci


## bash script to handle encrypted root filesystems 
# mkinitcpio -p 


## Install & Config a Bootloader (GRUB)

grub-install /dev/sda

# hidde menu at startup
echo "GRUB_FORCE_HIDDEN_MENU=true" >> /etc/default/grub
# add other operative systems (Mac, Windows, etc)
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub

url="https://gist.githubusercontent.com/anonymous/8eb2019db2e278ba99be/raw/257f15100fd46aeeb8e33a7629b209d0a14b9975/gistfile1.sh"
wget "${url}" -O /etc/grub.d/31_hold_shift
# asign permissions & re-generate bootloader
chmod a+x /etc/grub.d/31_hold_shift

grub-mkconfig -o /boot/grub/grub.cfg


## turn on "wheel" groups, required by sudo
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers


## Accounts Config
# set root password
echo -e "$root_password\n$root_password" | (passwd root)
# create new user
useradd -m "$user_name" -s /bin/bash
# set new user password
echo -e "$user_password\n$user_password" | (passwd $user_name)
# set user groups
usermod -aG wheel,audio,optical,storage,power,network "$user_name"

## create $USER dirs

pacman -S --needed --noconfirm xdg-user-dirs
LC_ALL=C xdg-user-dirs-update --force

# set user groups sample:
# usermod -aG wheel,audio,optical,storage,autologin,vboxusers,power,network <<user>>

## autologing tty
mkdir -p /etc/systemd/system/getty@tty1.service.d
printf "[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${user_name} --noclear %%I ${TERM}
" > /etc/systemd/system/getty@tty1.service.d/autologin.conf

# Make colorcoding available for everyone
cat <<EOF > /home/"${user_name}"/.bashrc
#
# ~/.bashrc
#

### BASH SCRIPT OPTIONS ##############################################

set -o errexit  # exit if script command fails
set -o nounset  # exit if script try to use undeclared variables
set -o pipefail # catch failed piped commands
# set -o xtrace   # trace what gets executed (useful for debugging)

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Make colorcoding available for everyone

Black='\[\e[0;30m\]'	# Black
Red='\[\e[0;31m\]'		# Red
Green='\[\e[0;32m\]'	# Green
Yellow='\[\e[0;33m\]'	# Yellow
Blue='\[\e[0;34m\]'		# Blue
Purple='\[\e[0;35m\]'	# Purple
Cyan='\[\e[0;36m\]'		# Cyan
White='\[\e[0;37m\]'	# White

# Bold
BBlack='\[\e[1;30m\]'	# Black
BRed='\[\e[1;31m\]'		# Red
BGreen='\[\e[1;32m\]'	# Green
BYellow='\[\e[1;33m\]'	# Yellow
BBlue='\[\e[1;34m\]'	# Blue
BPurple='\[\e[1;35m\]'	# Purple
BCyan='\[\e[1;36m\]'	# Cyan
BWhite='\[\e[1;37m\]'	# White

# Background
On_Black='\[\e[40m\]'	# Black
On_Red='\[\e[41m\]'		# Red
On_Green='\[\e[42m\]'	# Green
On_Yellow='\[\e[43m\]'	# Yellow
On_Blue='\[\e[44m\]'	# Blue
On_Purple='\[\e[45m\]'	# Purple
On_Cyan='\[\e[46m\]'	# Cyan
On_White='\[\e[47m\]'	# White

NC='\[\e[m\]'			# Color Reset

ALERT="${BWhite}${On_Red}" # Bold White on red background


# PERSONAL CUSTOMIZATION #############################################

[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases

# Set prompt
# PS1="${Yellow}\u@\h${NC}: ${Blue}\w${NC} \\$ "
# PS1="${Red}\u${NC}@\h: \w \\$ "
PS1="${BRed}\u@\h${NC}: ${BBlue}\w${NC} \\$ "

# set spell checker
shopt -s cdspell
EOF

## Enable Requited Services:
# network config
systemctl enable dhcpcd
systemctl enable NetworkManager
# run desktop environment at startup
# systemctl enable lightdm


## exit if no errors stops the script (option "set -ex")
exit


# Local Variables:
# sh-basic-offset: 2
# End:
