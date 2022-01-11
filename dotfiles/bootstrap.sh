#!/bin/bash
#
# ./bootstrap.sh
#  synchronize dotfile from working directory to $HOME/
# Requirements: rsync
if ! pacman -Qs rsync; then 
    echo "rsync: Command not found but required."
    read -p "Do you want to install rsync? (Y/n) " -n 1
    echo ""
    if [[ ! "$REPLY" =~ ^([nN][oO]|[nN])$ ]]; then
	sudo pacman -Syu --needed --noconfirm \
	     rsync 
    fi
fi

# Set the actual working directory
cd "$(dirname "${BASH_SOURCE}")"

# update changes in repository
git pull origin main

# perform synchonization of dotfiles
# from this working directory to $HOME directory
function doIt
{
    rsync --exclude ".git/" \
	  --exclude "bootstrap.sh" \
	  --exclude "README.org" \
	  --exclude "LICENSE" \
	  -avh --no-perms . ~

    source "$HOME"/.bashrc
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
    doIt
else
    read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
    echo ""
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
	doIt
    fi
fi
unset doIt


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:
