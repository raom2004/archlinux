set -x

localectl set-keymap --no-convert es

timedatectl set-ntp true

parted --script /dev/sda \
mklabel msdos \
mkpart primary ext4 1MiB 100% \
set 1 boot on

mount /dev/sda1 /mnt

reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
pacstrap /mnt base nano git glibc 

genfstab -L /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

arch-chroot /mnt
