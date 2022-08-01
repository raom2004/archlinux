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



## show final message and exit
echo "$0 successful" && sleep 3 && exit


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
