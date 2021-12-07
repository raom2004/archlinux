#!/bin/bash
#
# script2.sh: designed to run inside script1.sh chroot into new system   

## set bash options for: debugging

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

exit 1
# hidde menu at startup
echo "GRUB_FORCE_HIDDEN_MENU=true" >> /etc/default/grub
# add other operative systems (Mac, Windows, etc)
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
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
