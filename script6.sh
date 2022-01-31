#!/bin/bash
#
# ./script2.sh configure a new Arch Linux system and desktop
#
# Summary:
# * This script contain all the commands required to config
#   a new arch linux install and require arch-chroot.
# * This script also create a script3.desktop autostart app which
#   run the scrip3.sh on first boot to configure the new desktop 


### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING ###################

# shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


## Time Configuration 
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc


## Language Configuration (support for us, gb, dk, es, de)
sed -i 's/#\(de_DE.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(en_GB.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(en_US.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(es_ES.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(fr_FR.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(ru_RU.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(zh_CN.UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8'              >  /etc/locale.conf
echo 'LANGUAGE=en_US:en_GB:en'       >> /etc/locale.conf
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


## Setup Boot loader: GRUB
grub-install --target=i386-pc /dev/sda
# detect additional kernels or operative systems available
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
# hide boot loader at startup
echo "GRUB_FORCE_HIDDEN_MENU=true"  >> /etc/default/grub
# press shift to show boot loader menu at start up
url="https://gist.githubusercontent.com/anonymous/8eb2019db2e278ba99be/raw/257f15100fd46aeeb8e33a7629b209d0a14b9975/gistfile1.sh"
wget "${url}" -O /etc/grub.d/31_hold_shift
chmod a+x /etc/grub.d/31_hold_shift
# Config a boot loader GRUB
grub-mkconfig -o /boot/grub/grub.cfg


## Accounts Config
# sudo requires to turn on "wheel" groups
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
# set root password
echo -e "${root_password}\n${root_password}" | (passwd root)
# create new user and set ZSH as shell
useradd -m "$user_name" -s /bin/"${USER_SHELL}"
# set new user password
echo -e "${user_password}\n${user_password}" | (passwd $user_name)
# set user groups
usermod -aG audio,network,optical,power,storage,wheel "${user_name}"
# usermod -aG network,power,wheel,audio,optical,storage "${user_name}"



## shell support for: command not found
pacman -S --noconfirm pkgfile && pkgfile -u


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
# ~/.inputrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.inputrc"
wget "${url}" --output-document=/home/"${user_name}"/.inputrc
# ~/.zsh_prompt
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.zsh_prompt"
wget "${url}" --output-document=/home/"${user_name}"/.zsh_prompt
# ~/.vimrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.vimrc"
wget "${url}" --output-document=/home/"${user_name}"/.vimrc


## vim editor customization
# plugin support
url=https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
wget "${url}" -P /home/"${user_name}"/.vim/autoload
## install plugins without open vim
vim -E -s -u $HOME/.vimrc +PlugInstall +visual +qall


#~/.gitconfig
git config --global user.name "${GIT_GLOBAL_USER_NAME}"
git config --global user.email "${GIT_GLOBAL_USER_EMAIL}"
git config --global core.editor "${GIT_GLOBAL_CORE_EDITOR}"
git config --global init.DefaultBranch master # avoid git config warning


## STARTUP DESKTOP APPLICATIONS
# config desktop on first startup
mkdir -p $HOME/.config/autostart/
echo '[Desktop Entry]
Type=Application
Name=setup-desktop-on-first-startup
Comment[C]=Script to config a new Desktop on first boot
Terminal=true
Exec=xfce4-terminal -e "bash -c \"sudo bash \$HOME/script7.sh; exec bash\""
X-GNOME-Autostart-enabled=true
NoDisplay=false
' > $HOME/.config/autostart/script7.desktop
ls -la $HOME/.config/autostart/script7.desktop


## Pacman Package Manager Customization
sed -i 's/#\(Color\)/\1/' /etc/pacman.conf
# improve compiling time adding processors "nproc"
sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf
## autologing tty
mkdir -p /etc/systemd/system/getty@tty1.service.d
printf "[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${user_name} --noclear %%I $TERM
" > /etc/systemd/system/getty@tty1.service.d/autologin.conf


## start services on reboot:
systemctl enable dhcpcd		# ethernet
systemctl enable NetworkManager	# wifi


echo "$0 finished successfully" && exit


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
