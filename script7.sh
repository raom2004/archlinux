#!/bin/bash
#
#script7.sh create user configuration


# set environment variables
PWD=/home/"${user_name}"
LOGNAME="${user_name}"
HOME=/home/"${user_name}"
USER="${user_name}"


# set user locale 
mkdir -p $HOME/.config
echo 'LANGUAGE=en_GB.UTF-8' > $HOME/.config/locale.conf


## create $USER standard dotfiles
# ~/.bashrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.bashrc"
wget "${url}" --output-document=$HOME/.bashrc
# ~/.zshrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.zshrc"
wget "${url}" --output-document=$HOME/.zshrc


## create $USER CUSTOMIZED DOTFILES
# ~/.aliases
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.aliases"
wget "${url}" --output-document=$HOME/.aliases
# ~/.bash_prompt
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.bash_prompt"
wget "${url}" --output-document=$HOME/.bash_prompt
# ~/.functions
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.functions"
wget "${url}" --output-document=$HOME/.functions
# ~/.vimrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.vimrc"
wget "${url}" --output-document=$HOME/.vimrc


## create folder ~/.vim and vim plugin support
url=https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
wget "${url}" -P $HOME/.vim/autoload
## vim config
echo | vim -E -s -u "$HOME/.vimrc" +PlugInstall +qall


# config desktop on first startup
mkdir -p $HOME/.config/autostart/
echo '[Desktop Entry]
Type=Application
Name=script3
Comment[C]=Script to config a new Desktop on first boot
Terminal=true
Exec=gnome-terminal -- bash -c "sudo bash /usr/bin/script3.sh; exec bash"
X-GNOME-Autostart-enabled=true
NoDisplay=false
' > $HOME/.config/autostart/script3.desktop
ls -la $HOME/.config/autostart/script3.desktop


## RECTIFY USER PERMISSIONS
chown -R "${user_name}":"${user_name}" $HOME/.*


exit


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
