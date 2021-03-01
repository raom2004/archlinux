## set timedate 
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

## Set Language/keymap Using "localectl" (RECOMMENDED)
localectl set-locale LANG=en_US.UTF-8
locatectl --no-convert set-x11-keymap es,us pc105


## set host config
read -p "Enter hostname: " host_name
echo "$host_name" > /etc/hostname
bash -c "echo '127.0.0.1	localhost
::1		localhost
127.0.1.1	${host_name}.localdomain	$host_name' >> /etc/hosts"


## TODO: firmware modules pending: aic94xx wd719x xhci_pci

## optional
# mkinitcpio -p 


## install bootloader and config it
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

## turn on wheel, required by sudo 
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
# visudo

## set root password and add a new user
echo
printf "set root password\n"
passwd
echo
read -p "Enter USERNAME: " name
useradd -m $name # -s /bin/zsh 
echo
printf "Set $name PASSWORD\n"
passwd $name
usermod -aG wheel,audio,optical,storage,power,network $name

# usermod -aG wheel,audio,optical,storage,autologin,vboxusers,power,network $name

## enable requited services
# enable wired internet
systemctl enable dhcpcd 
# enable desktop environment at startup
systemctl enable lightdm


exit
