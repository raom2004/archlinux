#!/bin/bash
#
# ./script6b.sh Arch Linux user customization
#

### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING ###################

# shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


### SET USER CONFIGURATION ###########################################


# set environment variables
PWD=/home/"${user_name}"
LOGNAME="${user_name}"
HOME=/home/"${user_name}"
USER="${user_name}"


# Create USER directories
sudo pacman -S --needed --noconfirm xdg-user-dirs
if ! LC_ALL=C xdg-user-dirs-update --force; then
  sudo bash -c "LC_ALL=C xdg-user-dirs-update --force"
  echo 'sudo bash -c "LC_ALL=C xdg-user-dirs-update --force"'
fi


## shell support for: command not found
sudo pacman -S --noconfirm pkgfile && pkgfile -u


# set user locale (e.g. set system language but keep messages in english)
mkdir -p $HOME/.config
echo 'LANG=es_ES.UTF-8'        >  $HOME/.config/locale.conf
echo 'LANGUAGE=en_GB:en_US:en' >> $HOME/.config/locale.conf


## create $USER standard dotfiles
# ~/.bashrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.bashrc"
wget "${url}" --output-document=$HOME/.bashrc
# ~/.zshrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.zshrc"
wget "${url}" --output-document=$HOME/.zshrc
#~/.gitconfig
git config --global user.name "${git_global_user_name}"
git config --global user.email "${git_global_user_email}"
git config --global core.editor "${git_global_core_editor}"
git config --global init.DefaultBranch master # avoid git config warning


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
# ~/.inputrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.inputrc"
wget "${url}" --output-document=$HOME/.inputrc
# ~/.vimrc
url="https://raw.githubusercontent.com/raom2004/archlinux/master/dotfiles/.vimrc"
wget "${url}" --output-document=$HOME/.vimrc


## create folder ~/.vim and vim plugin support
url=https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
wget "${url}" -P $HOME/.vim/autoload
## install plugins without open vim
vim -E -s -u $HOME/.vimrc +PlugInstall +visual +qall


# config desktop on first startup
mkdir -p $HOME/.config/autostart/
echo '[Desktop Entry]
Type=Application
Name=script3
Comment[C]=Script to config a new Desktop on first boot
Terminal=true
Exec=xfce4-terminal -e "bash -c \"sudo bash \$HOME/script7.sh; exec bash\""
X-GNOME-Autostart-enabled=true
NoDisplay=false
' > $HOME/.config/autostart/script7.desktop
ls -la $HOME/.config/autostart/script7.desktop


### DISPLAY SERVER CONFIGURATION #####################################


# start xfce with file ~.xinitrc
head -n50 /etc/X11/xinit/xinitrc > $HOME/.xinitrc
# set keymap for xorg (es = spanish)
echo "setxkbmap es" >> $HOME/.xinitrc
# start xfce but let place to add other desktops in the future 
echo '
# Here Xfce is kept as default
session=${1:-xfce}

case $session in
    xfce|xfce4        ) exec startxfce4;;
    # No known session, try to run it as command
    *                 ) exec $1;;
esac
' >> $HOME/.xinitrc

## RECTIFY USER PERMISSION IN DOTFILES AND DOTFOLDERS
chown -R "${user_name}":"${user_name}" $HOME/.[a-z]*


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
