#!/bin/bash
#
# ./script2.sh configure a new Arch Linux system and desktop
#
# Summary:
# * This script contain the commands that runs inside chroot to custom a
#   new Arch Linux system.
# * This script also create a desktop autostart app to run the scrip3.sh #   on first boot to make the user desktop custmizations related. 
#
# Dependencies: ./script1.sh
# 
# Requirements: Root Privileges
if [[ "$EUID" -eq 0 ]]; then echo "./$0 require root priviledges"; fi


### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING

# shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


### ERROR HANDLING

out() { printf "$1 $2\n" "${@:3}"; }
error() { out "==> ERROR:" "$@"; } >&2
# warning() { out "==> WARNING:" "$@"; } >&2
# msg() { out "==>" "$@"; }
# msg2() { out "  ->" "$@";}
die() { error "$@"; exit 1; }


### TIME CONFIGURATION 

ln -sf /usr/share/zoneinfo"${local_time}" /etc/localtime \
  || die "can not set $_"
hwclock --systohc || die "can not set clock config"


### LANGUAGE CONFIGURATION (support for us, gb, dk, es, de)

sed -i 's/#\(en_US.UTF-8\)/\1/' /etc/locale.gen || die "can not set $_"
sed -i 's/#\(en_GB.UTF-8\)/\1/' /etc/locale.gen || die "can not set $_"
sed -i 's/#\(en_DK.UTF-8\)/\1/' /etc/locale.gen || die "can not set $_"
sed -i 's/#\(es_ES.UTF-8\)/\1/' /etc/locale.gen || die "can not set $_"
sed -i 's/#\(de_DE.UTF-8\)/\1/' /etc/locale.gen || die "can not set $_"
locale-gen || die "can not $_"
echo 'LANG=en_US.UTF-8'        >  /etc/locale.conf || die "LANG in $_"
echo 'LANGUAGE=en_US:en_GB:en' >> /etc/locale.conf || die "LANGUAGE in $_"
echo 'LC_COLLATE=C'            >> /etc/locale.conf || die "COLLATE in $_"
echo 'LC_MESSAGES=en_US.UTF-8' >> /etc/locale.conf || die "MESSAGES in $_"
echo 'LC_TIME=en_DK.UTF-8'     >> /etc/locale.conf || die "LC_TIME in $_"
# Keyboard Configuration (e.g. set spanish as keyboard layout)
# localectl set-keymap --no-convert es # do not work under chroot
echo "KEYMAP=${keyboard_keymap}"               > /etc/vconsole.conf \
  || die "can not set KEYMAP=${keyboard_keymap} in $_"


### Network Configuration

echo "${host_name}" > /etc/hostname || die "can not set $_"
echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	${host_name}.localdomain	${host_name}
" >> /etc/hosts || die "can not set $_"


### INIT RAM FILSESYSTEM: initramfs

## Initramfs was run for pacstrap but must be run for LVM, encryption...:
# mkinitcpio -P 


### BOOT LOADER (GRUB) CONFIG

## set display resolution bigger in virtual machine
[[ "${MACHINE}" == "VBox" ]] \
  && sed -i 's/\(GRUB_GFX_MODE=\)\(auto\)/\11024x768x32,\2/' \
	 /etc/default/grub \
  || die "can not set grub desired resolution 1024x768 in $_"
## detect additional kernels or operative systems available
sed -i 's/#\(GRUB_DISABLE_OS_PROBER=false\)/\1/' /etc/default/grub \
  || die "can not disable grub in $_"
## hide boot loader at startup
echo "GRUB_FORCE_HIDDEN_MENU=true"  >> /etc/default/grub \
  || die "can not hide grub menu in $_"
## press shift to show boot loader menu at start up
url="https://gist.githubusercontent.com/anonymous/8eb2019db2e278ba99be/raw/257f15100fd46aeeb8e33a7629b209d0a14b9975/gistfile1.sh"
wget "${url}" -O /etc/grub.d/31_hold_shift || die "can not set $_ "
chmod a+x /etc/grub.d/31_hold_shift || die "can not set permission to $_"
## Install & Config a boot loader GRUB
grub-install --target=i386-pc "${hdd_partitioning}" \
  || die "can not install grub on $_"
grub-mkconfig -o /boot/grub/grub.cfg || die "can not config grub"


### ACCOUNTS CONFIG

## sudo requires to turn on "wheel" groups
sed -i 's/# \(%wheel ALL=(ALL:ALL) ALL\)/\1/g' /etc/sudoers \
  || die "can not activate whell in $_"
## set root password
echo -e "${root_password}\n${root_password}" | (passwd root) \
  || die "can not set root password"
## create new user and set ZSH as shell
useradd -m "${user_name}" -s "${user_shell}" \
  || die "can not add user"
## set new user password
echo -e "${user_password}\n${user_password}" | (passwd $user_name) \
  || die "can not set user password"
## set user groups
usermod -aG wheel,audio,optical,storage,power,network "${user_name}" \
  || die "can not set user groups"


### PACMAN PACKAGE MANAGER CUSTOMIZATION

## turn color on
sed -i 's/#\(Color\)/\1/' /etc/pacman.conf || die "can not customize $_"
## improve compiling time adding processors "nproc"
sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf \
  || die "can not add processors to $_"


### START SERVICES ON REBOOT

## enable ethernet and wifi
systemctl enable dhcpcd	|| die "can not enable ethernet $_"
systemctl enable NetworkManager || die "can not enable wifi $_"
[[ "${MACHINE}" == "VBox" ]] && systemctl enable vboxservice \
    || die "can not enable virtualbox service $_"


### TTY AUTOLOGING AT STARTUP

mkdir -p /etc/systemd/system/getty@tty1.service.d \
  || die "can not create dir $_"
printf "[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${user_name} --noclear %%I $TERM
" > /etc/systemd/system/getty@tty1.service.d/autologin.conf \
  || die "can not create $_"


### CUSTOMIZE SHELL

## support for command not found
pacman -S --noconfirm pkgfile || die "can not install $_"
pkgfile -u || die "can not update with 'pkgflie -u'"


### USER SYSTEM CUSTOMIZATION ########################################

## set environment variables
HOME=/home/"${user_name}"

## Autostart X at login
echo 'if [[ -z "${DISPLAY}" ]] && [[ "${XDG_VTNR}" -eq 1 ]]; then
  exec startx
fi' > $HOME/.zprofile || die "can not create $_" 
echo 'if [[ -z "${DISPLAY}" ]] && [[ "${XDG_VTNR}" -eq 1 ]]; then
  exec startx
fi' >> $HOME/.bash_profile || die "can not create $_"


## create $USER dirs (LC_ALL=C, means everything in English)
pacman -S --needed --noconfirm xdg-user-dirs || die "can not install $_"
LC_ALL=C xdg-user-dirs-update --force || die 'can not create user dirs'

## Overriding system locale per $USER session
mkdir -p $HOME/.config || die "can not create $_"
echo 'LANG=es_ES.UTF-8'         > $HOME/.config/locale.conf \
  || die "can not set user LANG in $_"
echo 'LANGUAGE=en_GB:en_US:en' >> $HOME/.config/locale.conf \
  || die "can not set user LANGUAGE in $_"

## create dotfiles ".xinitrc" and ".serverrc"
#   * source: https://wiki.archlinux.org/title/Xinit#xinitrc
# ~/.xinitrc: create from template
head -n50 /etc/X11/xinit/xinitrc > $HOME/.xinitrc \
  || die "can not create $_ from template /etc/X11/xinit/xinitrc"
# set keyboard keymap in .xinitrc
echo "setxkbmap ${keyboard_keymap}" >> $HOME/.xinitrc \
  || die "can not set keymap by setxkbmap"
unset keyboard_keymap || die "can not unset $_"
# set xfce as default and let place to add other desktops in the future 
echo '# Here Xfce is kept as default
session=${1:-xfce}

case $session in
    xfce|xfce4        ) exec startxfce4;;
    # No known session, try to run it as command
    *                 ) exec $1;;
esac
' >> $HOME/.xinitrc || die "can not set xfce4 desktop in ~/.xinitrc"

## install vim plugin manager
url=https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
wget "${url}" -P $HOME/.vim/autoload \
  || die 'can not populate vim plugin folder ~/.vim/autoload'
## TODO: install vim plugins without open vim (do not run as root)
# vim -E -s -u $HOME/.vimrc +PlugInstall +visual +qall


## add hunspell dictionaty of english medical terms: en_med_glut.dic 
#  source: https://github.com/Glutanimate/hunspell-en-med-glut
url=https://raw.githubusercontent.com/glutanimate/hunspell-en-med-glut/master/en_med_glut.dic
# wget "${url}" -P $HOME/Downloads/hunspell-1.3.2-3-w32-bin/share/hunspell
wget "${url}" -P /usr/share/hunspell
unset url

## How to customize a new desktop on first boot?
# With a startup script that just need to steps:
#  * Create a script3.sh with your customizations
#  * Create script3.desktop entry to autostart script3.sh at first boot
# create autostart dir and desktop entry
mkdir -p $HOME/.config/autostart/ \
  || die " can not create dir $_" 
echo '[Desktop Entry]
Type=Application
Name=setup-desktop-on-first-startup
Comment[C]=Script to config a new Desktop on first boot
Terminal=true
Exec=xfce4-terminal -e "bash -c \"bash \$HOME/Projects/archlinux/script3.sh; exec bash\""
X-GNOME-Autostart-enabled=true
NoDisplay=false
' > $HOME/.config/autostart/script3.desktop \
  || die "can not create $_"


echo "$0 successful" && sleep 3 && exit


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
