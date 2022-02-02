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


### error handling
out() { printf "$1 $2\n" "${@:3}"; }
error() { out "==> ERROR:" "$@"; } >&2
warning() { out "==> WARNING:" "$@"; } >&2
msg() { out "==>" "$@"; }
msg2() { out "  ->" "$@";}
die() { error "$@"; exit 1; }


## Time Configuration 
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
    || die "can not set $_"
hwclock --systohc || die "can not set clock config"


## Language Configuration (support for us, gb, dk, es, de)
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
echo 'KEYMAP=es'               > /etc/vconsole.conf \
    || die "can not set KEYMAP in $_"


## Network Configuration
echo "${host_name}" > /etc/hostname || die "can not set $_"
echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	${host_name}.localdomain	${host_name}
" >> /etc/hosts || die "can not set $_"


## Init ram filsesystem: Initramfs
# Initramfs was run for pacstrap but must be run for LVM, encryption...:
# mkinitcpio -P 


## Boot loader GRUB
# detect additional kernels or operative systems available
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub \
    || die "can not disable grub in $_"
# hide boot loader at startup
echo "GRUB_FORCE_HIDDEN_MENU=true"  >> /etc/default/grub \
    || die "can not hide grub menu in $_"
# press shift to show boot loader menu at start up
url="https://gist.githubusercontent.com/anonymous/8eb2019db2e278ba99be/raw/257f15100fd46aeeb8e33a7629b209d0a14b9975/gistfile1.sh"
wget "${url}" -O /etc/grub.d/31_hold_shift || die "can not set $_ "
chmod a+x /etc/grub.d/31_hold_shift || die "can not set permission to $_"
# Install & Config a boot loader GRUB
grub-install --target=i386-pc /dev/sda || die "can not install grub"
grub-mkconfig -o /boot/grub/grub.cfg || die "can not config grub"


## Accounts Config
# sudo requires to turn on "wheel" groups
sed -i 's/# \(%wheel ALL=(ALL:ALL) ALL\)/\1/g' /etc/sudoers \
    || die "can not activate whell in $_"
# set root password
echo -e "${root_password}\n${root_password}" | (passwd root) \
    || die "can not set root password"
# create new user and set ZSH as shell
useradd -m "${user_name}" -s /bin/"${user_shell}" \
    || die "can not add user"
# set new user password
echo -e "${user_password}\n${user_password}" | (passwd $user_name) \
    || die "can not set user password"
# set user groups
usermod -aG wheel,audio,optical,storage,power,network "${user_name}" \
    || die "can not set user groups"


## Pacman Package Manager Customization
sed -i 's/#\(Color\)/\1/' /etc/pacman.conf || die "can not customize $_"
# improve compiling time adding processors "nproc"
sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf \
    || die "can not add processors to $_"
## autologing tty
mkdir -p /etc/systemd/system/getty@tty1.service.d \
    || die "can not create dir $_"
printf "[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${user_name} --noclear %%I $TERM
" > /etc/systemd/system/getty@tty1.service.d/autologin.conf \
    || die "can not create $_"


## start services on reboot:
systemctl enable dhcpcd	|| die "can not enable ethernet $_"
systemctl enable NetworkManager || die "can not enable wifi $_"


## How to customize a new desktop on first boot?
# With a startup script that just need to steps:
#  * Create a script3.sh with your customizations
#  * Create script3.desktop entry to autostart script3.sh at first boot
# create autostart dir and desktop entry
mkdir -p /home/"${user_name}"/.config/autostart/ \
    || die " can not create dir $_" 
echo '[Desktop Entry]
Type=Application
Name=setup-desktop-on-first-startup
Comment[C]=Script to config a new Desktop on first boot
Terminal=true
Exec=xfce4-terminal -e "bash -c \"sudo bash \$HOME/script3.sh; exec bash\""
X-GNOME-Autostart-enabled=true
NoDisplay=false
' > /home/"${user_name}"/.config/autostart/script3.desktop \
    || die "can not create $_"
# set desktop entry permissions
chown "${user_name}:${user_name}" \
      /home/"${user_name}"/.config/autostart/script3.desktop \
    || die "can not set user permissions to $_"


echo "$0 successful" && sleep 3 && exit