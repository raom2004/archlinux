# reflector --country Germany --country Austria \
# 	  --verbose --latest 2 --sort rate \
# 	  --save /etc/pacman.d/mirrorlist

ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

hwclock --systohc

# nano /etc/locale.gen
sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen
locale-gen

echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=es' > /etc/vconsole.conf
echo "angel" > /etc/hostname
echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	myhostname.localdomain	myhostname" >> /etc/hosts

# firmware modules pending: aic94xx wd719x xhci_pci

# mkinitcpio -p

grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# visudo
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers


printf "set root password\n"
passwd
echo
read -p "Enter USERNAME: " name
useradd -m $name
echo
# useradd -m $name -s /bin/zsh
printf "Set $name PASSWORD\n"
passwd $name
usermod -aG wheel,audio,optical,storage,power,network $name

# usermod -aG wheel,audio,optical,storage,autologin,vboxusers,power,network $name

systemctl enable dhcpcd

# systemctl enable lightdm

# exit
