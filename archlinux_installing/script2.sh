#!/bin/bash
set -xe


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
echo 'LANGUAGE=en_US:en_UK:en:es:de' >> /etc/locale.conf
echo 'LC_COLLATE=C'                  >> /etc/locale.conf
echo 'LC_MESSAGES=en_US.UTF-8'       >> /etc/locale.conf
echo 'LC_TIME=en_DK.UTF-8'           >> /etc/locale.conf


## Keyboard Configuration
localectl set-keymap --no-convert es
# pacman -S libxkbcommon --noconfirm 
# localectl set-x11-keymap "es,us" pc105


## Network Configuration
echo "$host_name" > /etc/hostname
bash -c "echo '127.0.0.1	localhost
::1		localhost
127.0.1.1	${host_name}.localdomain	$host_name' >> /etc/hosts"


## TODO: Western Digital firmware modules pending: aic94xx wd719x xhci_pci


## bash script to handle encrypted root filesystems 
# mkinitcpio -p 


## Install & Config a Bootloader
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg


## turn on "wheel" groups, required by sudo
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers


## Accounts Config
# set root password
echo -e "$root_password\n$root_password" | (passwd root)
# create new user
useradd -m "$user_name" -s /bin/zsh
# set new user password
echo -e "$user_password\n$user_password" | (passwd $user_name)
# set user groups
usermod -aG wheel,audio,optical,storage,power,network "$user_name"

# set user groups sample:
# usermod -aG wheel,audio,optical,storage,autologin,vboxusers,power,network <<user>>


## Enable Requited Services:
# network config
systemctl enable dhcpcd
systemctl enable NetworkManager
# run desktop environment at startup
systemctl enable lightdm


## run script3.sh (desktop configuration) at first desktop boot
# echo '[Desktop Entry]
# Type=Application
# Version=1.0
# Name=script3
# Comment[C]=Script for basic config of Cinnamon Desktop
# Comment[es]=Script para la configuración básica del escritorio Cinnamon
# Exec=gnome-terminal -- bash -c "sh /usr/bin/script3.sh;exec bash"
# X-GNOME-Autostart-enabled=true
# NoDisplay=false' > /etc/xdg/autostart/script3.desktop


## exit if no errors stops the script (option "set -ex")
exit
