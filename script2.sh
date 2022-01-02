#!/bin/bash
#
# ./script2.sh configure a new Arch Linux system and desktop
#
# Summary:
# * This script contain all the commands required to config
#   a new arch linux system from inside using arch-chroot.
# * This script create a script3.dektop autostart app to
#   run the scrip3.sh on first boot and configure the new desktop 


## show all the command that get executed and exit if anything fails
set -xe


## Time Configuration 
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc


## Language Configuration (support for us, gb, dk, es, de)
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/#en_GB.UTF-8/en_GB.UTF-8/' /etc/locale.gen
sed -i 's/#en_DK.UTF-8/en_DK.UTF-8/' /etc/locale.gen
sed -i 's/#es_ES.UTF-8/es_ES.UTF-8/' /etc/locale.gen
sed -i 's/#de_DE.UTF-8/de_DE.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8'              >  /etc/locale.conf
echo 'LANGUAGE=en_US:en_GB:en:'      >> /etc/locale.conf
echo 'LC_COLLATE=C'                  >> /etc/locale.conf
echo 'LC_MESSAGES=en_US.UTF-8'       >> /etc/locale.conf
echo 'LC_TIME=en_DK.UTF-8'           >> /etc/locale.conf
# Keyboard Configuration (e.g. set spanish as keyboard layout)
localectl set-keymap --no-convert es


## Network Configuration
echo "${host_name}" > /etc/hostname
echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	${host_name}.localdomain	${host_name}
" >> /etc/hosts


## Init ram filsesystem: Initramfs
# Initramfs was run for pacstrap but must be run for LVM, encryption...:
# mkinitcpio -P 


## Install & Config a Bootloader
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg


## Accounts Config
# sudo requires to turn on "wheel" groups
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
# set root password
echo -e "$root_password\n$root_password" | (passwd root)
# create new user and set ZSH as shell
useradd -m "$user_name" -s /bin/zsh
# set new user password
echo -e "$user_password\n$user_password" | (passwd $user_name)
# set user groups
usermod -aG wheel,audio,optical,storage,power,network "$user_name"


## Enable Requited Services:
# enable ethernet
systemctl enable dhcpcd
# enable wifi
systemctl enable NetworkManager
# run xfce desktop environment in next boot
systemctl enable lightdm


## Hot to customize a new desktop on first boot?
# With a startup script that just need to steps:
#  * Create a script3.sh with your customizations
#  * Create script3.desktop entry to autostart script3.sh at first boot
echo '[Desktop Entry]
Type=Application
Name=script3
Comment[C]=Script to config a new Desktop on first boot
Exec=/usr/bin/bash -c "bash /usr/bin/script3.sh;exec bash"
Terminal=true
X-GNOME-Autostart-enabled=true
NoDisplay=false' > /etc/xdg/autostart/script3.desktop


## exit if no errors stops the script (option "set -ex")
exit