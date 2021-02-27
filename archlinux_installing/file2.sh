ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

hwclock --systohc

# nano /etc/locale.gen
sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
locale-gen

LANG=en_US.UTF-8 > /etc/locale.conf
KEYMAP=es > /etc/vconsole.conf

echo "angel" > /etc/hostname

echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	myhostname.localdomain	myhostname" >> /etc/hosts

# firmware modules pending: aic94xx wd719x xhci_pci

git clone https://aur.archlinux.org/aic94xx-firmware.git
cd aic94xx-firmware
makepkg -sri
cd $PWD

git clone https://aur.archlinux.org/wd719x-firmware.git
cd wd719x-firmware
makepkg -sri
cd $PWD

git clone https://aur.archlinux.org/upd72020x-fw.git
cd upd72020x-fw
makepkg -sri
cd $PWD

mkinitcpio -p

# habilitate internet
# pacman -S dhcpdc
systemctl enable dhcpcd

# install sudo
# pacman -S sudo
# pacman -S vim
visudo

# set root password
passwd

# create user
useradd -m angel
passwd angel
usedmod -aG wheel,video,audio,optical,storage angel

# install grub
# pacman -S grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
