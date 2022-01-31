## Accounts Config
# sudo requires to turn on "wheel" groups
sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
# set root password
echo -e "${root_password}\n${root_password}" | (passwd root)
# create new user and set ZSH as shell
useradd -m "$user_name" -s /bin/zsh
# set new user password
echo -e "${user_password}\n${user_password}" | (passwd $user_name)
# set user groups
usermod -aG network,power,wheel,audio,optical,storage "${user_name}"


## start services on reboot:
systemctl enable dhcpcd		# ethernet
systemctl enable NetworkManager	# wifi


## shell support for: command not found
pacman -S --noconfirm pkgfile && pkgfile -u
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


# Create USER directories
pacman -S --needed --noconfirm xdg-user-dirs
LC_ALL=C xdg-user-dirs-update --force


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
