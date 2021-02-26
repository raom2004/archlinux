set -x

localectl set-keymap --no-convert es

reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

timedatectl set-ntp true

# /boot
mkfs.ext2 /dev/sda1
# /
mkfs.ext4 /dev/sda2

mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

pacstrap /mnt base nano

genfstab -L /mnt >> /mnt/etc/fstab

arch-chroot /mnt

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

# habilitate internet
pacman -S dhcpdc
systemctl enable dhcpcd

# install sudo
pacman -S sudo
pacman -S vim
visudo

# set root password
passwd

# create user
useradd -m angel
passwd angel
usedmod -aG wheel,video,audio,optical,storage angel

# install grub
pacman -S grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
