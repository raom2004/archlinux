#
# /bootstrap.sh
#  synchronize dotfile from working directory to $HOME/
# Requirements: rsync
if ! pacman -Qs rsync; then 
    echo "Command not found but required: rsync
You can install with: sudo pacman -Syu rsync"
    exit 0
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
	source ~/.bashrc
}

if [ "${1}" == "--force" -o "${1}" == "-f" ]; then
	doIt
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
	echo ""
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt
	fi
fi
unset doIt
