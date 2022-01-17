#!/bin/bash
#
# ./script1.sh is a script to install Arch Linux amd configure a desktop
#
# Summary:
# * This script contain all the commands required to prepare a system
#   for a new Arch Linux installation.
# * This script also call the script2.sh to execute all the commands
#   that must be run inside the new Arch Linux install, by arch-chroot.


## show what get executed and exit if any command fails
set -xe


## Declare variables to use in script2.sh. Hide passwords by -sp option.
read -p "Enter hostname: " host_name
read -sp "Enter ROOT password: " root_password
read -p "Enter NEW user: " user_name
read -sp "Enter NEW user PASSWORD: " user_password
# make these variables available for script2.sh
export host_name
export root_password
export user_name
export user_password


## set time and synchronize system clock
timedatectl set-ntp true


## HDD partitioning (BIOS/MBR)
parted -s /dev/sda \
       mklabel msdos \
       mkpart primary ext2 0% 2% \
       set 1 boot on \
       mkpart primary ext4 2% 100%


## HDD patitions formating (-F=overwrite if necessary)
mkfs.ext2 -F /dev/sda1
mkfs.ext4 -F /dev/sda2


## HDD partitions mounting
# root partition "/"
mount /dev/sda2 /mnt
# boot partition "/boot"
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot


## Important: update package manager keyring before install packages
pacman -Syy --noconfirm archlinux-keyring


## install system packages (with support for wifi and ethernet)
pacstrap /mnt base base-devel linux \
	 zsh sudo vim git wget \
	 dhcpcd \
	 networkmanager \
	 grub # os-prober \
	 # xorg-server lightdm lightdm-gtk-greeter \
	 # gnome-terminal terminator cinnamon livecd-sounds \
	 # firefox \
	 # virtualbox-guest-utils
	 
	 
## generate file system table
genfstab -L /mnt >> /mnt/etc/fstab


## scripting inside chroot from outside: script2.sh
# copy script2.sh to new system
# cp ./script2.sh /mnt/home
# # run script2.sh commands inside chroot
# arch-chroot /mnt bash /home/script2.sh
# # remove script2.sh after completed
# rm /mnt/home/script2.sh


# ## Copy script3.sh with desktop customizations to run on first boot 
# cp ./script3.sh /mnt/usr/bin/script3.sh
# chmod +x /mnt/usr/bin/script3.sh

### commands inside new system: chroot

## Time Configuration 
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
arch-chroot /mnt hwclock --systohc


## Language Configuration (support for us, gb, dk, es, de)
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /mnt/etc/locale.gen
sed -i 's/#en_GB.UTF-8/en_GB.UTF-8/' /mnt/etc/locale.gen
sed -i 's/#en_DK.UTF-8/en_DK.UTF-8/' /mnt/etc/locale.gen
sed -i 's/#es_ES.UTF-8/es_ES.UTF-8/' /mnt/etc/locale.gen
sed -i 's/#de_DE.UTF-8/de_DE.UTF-8/' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo 'LANG=en_US.UTF-8'              >  /mnt/etc/locale.conf
echo 'LANGUAGE=en_US:en_GB:en:'      >> /mnt/etc/locale.conf
echo 'LC_COLLATE=C'                  >> /mnt/etc/locale.conf
echo 'LC_MESSAGES=en_US.UTF-8'       >> /mnt/etc/locale.conf
echo 'LC_TIME=en_DK.UTF-8'           >> /mnt/etc/locale.conf
# Keyboard Configuration (e.g. set spanish as keyboard layout)
# localectl set-keymap --no-convert es # do not work as chroot command
echo 'KEYMAP=es' > /mnt/etc/vconsole.conf


## Network Configuration
echo "${host_name}" > /mnt/etc/hostname
echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	${host_name}.localdomain	${host_name}
" >> /mnt/etc/hosts


## Init ram filsesystem: Initramfs
# Initramfs was run for pacstrap but must be run for LVM, encryption...:
# mkinitcpio -P 


## Install & Config a Bootloader
arch-chroot /mnt grub-install /dev/sda
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg


## Accounts Config
# sudo requires to turn on "wheel" groups
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /mnt/etc/sudoers
# set root password
arch-chroot /mnt \
	    echo -e "${root_password}\n${root_password}" | (passwd root)
# create new user and set ZSH as shell
arch-chroot /mnt useradd -m "$user_name" -s /bin/zsh
# set new user password
arch-chroot /mnt echo -e "${user_password}\n${user_password}" | (passwd $user_name)
# set user groups
arch-chroot /mnt usermod -aG wheel,audio,optical,storage,power,network "${user_name}"


## DOTFILES
# ~/.bashrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.bashrc"
# wget "${url}" --output-document=/home/"${user_name}"/.bashrc
arch-chroot -u "${user_name}" /mnt \
	    wget "${url}" \
	    --output-document=/home/"${user_name}"/.bashrc
# chown "${user_name}:${user_name}" /home/"${user_name}"/.bashrc
# ~/.zshrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.zshrc"
arch-chroot -u "${user_name}" /mnt \
	    wget "${url}" --output-document=/home/"${user_name}"/.zshrc
# chown "${user_name}:${user_name}" /home/"${user_name}"/.zshrc

## CUSTOMIZED DOTFILES
# ~/.aliases
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.aliases"
arch-chroot -u "${user_name}" /mnt \
	    wget "${url}" --output-document=/home/"${user_name}"/.aliases
# chown "${user_name}:${user_name}" /home/"${user_name}"/.aliases
# ~/.bash_prompt
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.bash_prompt"
arch-chroot -u "${user_name}" /mnt \
	    wget "${url}" --output-document=/home/"${user_name}"/.bash_prompt
# chown "${user_name}:${user_name}" /home/"${user_name}"/.bash_prompt
# ~/.functions
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.functions"
arch-chroot -u "${user_name}" /mnt \
	    wget "${url}" --output-document=/home/"${user_name}"/.functions
# chown "${user_name}:${user_name}" /home/"${user_name}"/.functions


## Enable Requited Services:
# enable ethernet
arch-chroot /mnt systemctl enable dhcpcd
# enable wifi
arch-chroot /mnt systemctl enable NetworkManager
# run xfce desktop environment in next boot
arch-chroot /mnt systemctl enable lightdm

## In the end unmount everything and exiting
umount -R /mnt
shutdown now
