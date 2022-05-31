#!/bin/bash
#
# ./install-xfce.sh install xfce desktop and set customization
#
# Summary:
#  * install xfce desktop packages
#  * configure .xinitrc to start xfce session on startup
#  * customize xfce desktop on startup
#
# Dependencies: ../script1.sh
#
### CODE:

### Requirements:

# check priviledges
if [[ "$EUID" -ne 0 ]]; then
  echo "error: run ./$0 require root priviledges"
  exit
fi


### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING

# shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


### ERROR HANDLING

out() { printf "$1 $2\n" "${@:3}"; }
error() { out "==> ERROR:" "$@"; } >&2
warning() { out "==> WARNING:" "$@"; } >&2
msg() { out "==>" "$@"; }
msg2() { out "  ->" "$@";}
die() { error "$@"; exit 1; }


### INSTALL DESKTOP XFCE
## set environment variables
HOME=/home/"${user_name}"

## install packages from a list
pacstrap /mnt --needed --noconfirm - < pkglist.txt \
    || die 'Pacstrap can not install the packages'
# pacstrap /mnt --needed --noconfirm - < ./desktop/xfce/pkglist.txt

## configure .xinitrc to start xfce session on startup 
if ! grep '-xfce' $HOME/.xinitrc; then
    echo '# Here Xfce is kept as default
session=${1:-xfce}

case $session in
    xfce|xfce4        ) exec startxfce4;;
    # No known session, try to run it as command
    *                 ) exec $1;;
esac
' >> $HOME/.xinitrc || die "can not set xfce4 desktop in ~/.xinitrc"
fi

## How to customize a new desktop on first boot?
# With a startup script that just need to steps:
#  * Create a script3.sh with your customizations
#  * Create script3.desktop entry to autostart script3.sh at first boot
# create autostart dir and desktop entry
mkdir -p $HOME/.config/autostart/ \
  || die " can not create dir $_" 
echo '[Desktop Entry]
Type=Application
Name=setup-desktop-on-first-startup
Comment[C]=Script to config a new Desktop on first boot
Terminal=true
Exec=xfce4-terminal -e "bash -c \"bash \$HOME/Projects/archlinux/script3.sh; exec bash\""
X-GNOME-Autostart-enabled=true
NoDisplay=false
' > $HOME/.config/autostart/script3.desktop || die "can not create $_"


## show final message and exit
echo "$0 successful" && sleep 3 && exit


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
