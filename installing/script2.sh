#!/bin/bash
#
# configure_system.sh: an chroot script to config a the system parameters:
#  locale, keymap, host, bootloader, user permissions, ethernet & wifi

# Dependencies:
#  9 positional arguments


### PREREQUIREMENTS ##################################################

##  Verify Internet Connection
if ! ping -c 1 -q google.com >&/dev/null; then
  echo "Internet required. Cancelling install.."
  exit 0
fi

## Verify Root Priviledges
ROOT_UID=0   # Root has $UID 0.
if [[ ! "$UID" -eq "$ROOT_UID" ]]; then
  echo "ROOT priviledges required. Cancelling install.."
  exit 0
fi
######################################################################


## variable declaration: get positional arguments
target_device="$1"
host_name="$2"
root_password="$3"
user_name="$4"
user_password="$5"
user_shell="$6"
shell_keymap="$7"
autolog_tty="$8"


# trace & expand what gets executed 
set -o xtrace


## Time Configuration
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc


## Language Configuration: including frequent languages
sed -i 's/#\(de_DE.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(en_GB.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(en_US.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(es_ES.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(fr_FR.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(ru_RU.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(zh_CN.UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8'         > /etc/locale.conf
echo 'LANGUAGE=en_US:en_GB:en'  >> /etc/locale.conf
echo 'LC_COLLATE=C'             >> /etc/locale.conf
echo 'LC_MESSAGES=en_US.UTF-8'  >> /etc/locale.conf
echo 'LC_TIME=en_GB.UTF-8'      >> /etc/locale.conf
# Keyboard Configuration
echo "KEYMAP=${shell_keymap}" > /etc/vconsole.conf
localectl set-keymap --no-convert es # do not work under chroot


## Network Configuration
echo "${host_name}" > /etc/hostname
echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	${host_name}.localdomain	${host_name}
" >> /etc/hosts


## TODO: Western Digital firmware modules pending: aic94xx wd719x xhci_pci


## bash script to handle encrypted root filesystems 
# mkinitcpio -p 


## Install & Config a Bootloader (GRUB)
# grub-install "${target_device}"
# https://wiki.archlinux.org/title/GRUB/Tips_and_tricks#Multiple_entries
grub-install --target=i386-pc "${target_device}"
# add other operative systems (Mac, Windows, etc)
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
# if autologging yes, hidde GRUB menu at startup
if [[ "${autolog_tty}" =~ ^([yY][eE][sS]|[yY])$ ]];then
  echo "GRUB_FORCE_HIDDEN_MENU=true" >> /etc/default/grub
  url="https://gist.githubusercontent.com/anonymous/8eb2019db2e278ba99be/raw/257f15100fd46aeeb8e33a7629b209d0a14b9975/gistfile1.sh"
  wget "${url}" -O /etc/grub.d/31_hold_shift
  # asign permissions & re-generate bootloader
  chmod a+x /etc/grub.d/31_hold_shift
fi


## Accounts Config
# turn on "wheel" groups, required by sudo
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
# set root password
echo -e "${root_password}\n${root_password}" | (passwd root)
# create new user
useradd -m "${user_name}" -s /bin/"${user_shell}"
# set new user password
echo -e "${user_password}\n${user_password}" | (passwd $user_name)
# set user groups
usermod -aG audio,network,optical,power,storage,wheel "${user_name}"
# Note: there are more groups available, like: autologin,kvm,vboxusers,lp


## create $USER dirs (ENGLISH)
pacman -S --needed --noconfirm xdg-user-dirs
LC_ALL=C xdg-user-dirs-update --force


## Overriding system locale per $USER session
mkdir -p /home/"${user_name}"/.config
echo 'LANGUAGE=en_GB.UTF-8' > /home/"${user_name}"/.config/locale.conf


## create $USER standard dotfiles
# ~/.bashrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.bashrc"
wget "${url}" --output-document=/home/"${user_name}"/.bashrc
# ~/.zshrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.zshrc"
wget "${url}" --output-document=/home/"${user_name}"/.zshrc


## create $USER CUSTOMIZED DOTFILES
# ~/.aliases
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.aliases"
wget "${url}" --output-document=/home/"${user_name}"/.aliases
# ~/.bash_prompt
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.bash_prompt"
wget "${url}" --output-document=/home/"${user_name}"/.bash_prompt
# ~/.functions
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.functions"
wget "${url}" --output-document=/home/"${user_name}"/.functions
# ~/.vimrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.vimrc"
wget "${url}" --output-document=/home/"${user_name}"/.vimrc
# folder ~/.vim and vim plugin support
url=https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
wget "${url}" -P /home/"${user_name}"/.vim/autoload

## RECTIFY DOTFILES PERMISSIONS 
chown -R "${user_name}":"${user_name}" /home/"${user_name}"/.*


## shell support for: command not found
pacman -S --noconfirm pkgfile && pkgfile -u


## Pacman Package Manager Customization
sed -i 's/#\(Color\)/\1/' /etc/pacman.conf
# improve compiling time adding processors "nproc"
sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf

## autologing tty
if [[ "${autolog_tty}" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  mkdir -p /etc/systemd/system/getty@tty1.service.d
  printf "[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${user_name} --noclear %%I $TERM
" > /etc/systemd/system/getty@tty1.service.d/autologin.conf
fi


## Enable Requited Services
systemctl enable dhcpcd		# ethernet
systemctl enable NetworkManager	# wifi


## run desktop environment at startup
# systemctl enable lightdm


exit


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
