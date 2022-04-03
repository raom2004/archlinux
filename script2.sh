#!/bin/bash
#
# ./script2.sh configure a new Arch Linux system and desktop
#
# Summary:
# * This script contain all the commands required to config
#   a new arch linux install and require arch-chroot.
# * This script also create a script3.desktop autostart app which
#   run the scrip3.sh on first boot to configure the new desktop 


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
# localectl set-keymap --no-convert es # do not work under chroot
echo 'KEYMAP=es'                     > /etc/vconsole.conf


## Network Configuration
echo "${host_name}" > /etc/hostname
echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	${host_name}.localdomain	${host_name}
" >> /etc/hosts


## Init ram filsesystem: Initramfs
# Initramfs was run for pacstrap but must be run for LVM, encryption...:
# mkinitcpio -P 


## Boot loader GRUB
# detect additional kernels or operative systems available
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
# hide boot loader at startup
echo "GRUB_FORCE_HIDDEN_MENU=true"  >> /etc/default/grub
# press shift to show boot loader menu at start up
url="https://gist.githubusercontent.com/anonymous/8eb2019db2e278ba99be/raw/257f15100fd46aeeb8e33a7629b209d0a14b9975/gistfile1.sh"
wget "${url}" -O /etc/grub.d/31_hold_shift
chmod a+x /etc/grub.d/31_hold_shift
# Install & Config a boot loader GRUB
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg


## Accounts Config
# sudo requires to turn on "wheel" groups
sed -i 's/# \(%wheel ALL=(ALL:ALL) ALL\)/\1/g' /etc/sudoers
# set root password
echo -e "${root_password}\n${root_password}" | (passwd root)
# create new user and set ZSH as shell
useradd -m "$user_name" -s /bin/zsh
# set new user password
echo -e "${user_password}\n${user_password}" | (passwd "${user_name}")
# set user groups
usermod -aG wheel,audio,optical,storage,power,network "${user_name}"


## Enable Requited Services:
# enable ethernet
systemctl enable dhcpcd
# enable wifi
systemctl enable NetworkManager
# run xfce desktop environment in next boot
systemctl enable lightdm

## How to customize a new desktop on first boot?
# With a startup script that just need to steps:
#  * Create a script3.sh with your customizations
#  * Create script3.desktop entry to autostart script3.sh at first boot
# create autostart dir and desktop entry
mkdir -p /home/"${user_name}"/.config/autostart/
echo "[Desktop Entry]
Type=Application
Name=script3
Comment[C]=Script to config a new Desktop on first boot
Exec=gnome-terminal -- bash -c \"bash /home/${user_name}/script3.sh; exec bash\"
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=0
NoDisplay=false
Hidden=false
" > /home/"${user_name}"/.config/autostart/script3.desktop
# set desktop entry permissions
chown "${user_name}:${user_name}" \
      /home/"${user_name}"/.config/autostart/script3.desktop
# saved usseful lines
# Exec=/usr/bin/bash -c "bash /usr/bin/script3.sh;exec bash"
# NoDisplay=false' > /etc/xdg/autostart/script3.desktop

## exit if no errors stops the script (option "set -ex")
exit
