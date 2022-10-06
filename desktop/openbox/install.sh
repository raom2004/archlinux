#!/bin/bash
#
# ./install-openbox.sh install and customize openbox window manager
#
# Summary:
#  * install openbox desktop packages
#  * configure .xinitrc to start openbox session on startup
#  * customize openbox desktop on startup
#
# Dependencies: ../script1.sh
#
### CODE:


### REQUIREMENTS:

# Basic Verifications
if [[ "$EUID" -eq 0 ]]; then	 # user privileges
  echo "Do not run ./$0 as root!"
  exit
else
  system_desktop="$(basename $PWD)"
  echo "running $0"
  read -p "Allow run ./$0 to customize the desktop ${system_desktop}?[Y/n]" answer
  [[ "${answer:-Y}" =~ ^([nN])$ ]] && exit
  unset answer
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


### install desktop

read -p "::Install ${system_desktop} desktop? [y/N]" install_desktop
if [[ "${install_desktop}" =~ ^([yY])$ ]]; then
  # install packages
  sudo pacman -Syu --needed --noconfirm - < pkglist.txt \
    || die "Pacman can not install the packages $_"
  ## show final message and exit
  echo "$0 successful" && sleep 3 && exit
else 
  echo "Desktop ${system_desktop} will nos be installed"
fi


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
