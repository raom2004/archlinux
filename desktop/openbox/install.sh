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
elif ! source ~/.functions; then # source dependencies
  echo "can not source ~/.functions" && sleep 3
  exit
elif ! check_internet; then	 # internet connection
  echo "can not run function: check_internet" && sleep 3
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
  packages_to_install=$HOME/Projects/archlinux/desktop/"${system_desktop}"/pkglist.txt
  readarray -t DesktopPkg < "${packages_to_install}"
  Packages=(${DesktopPkg[@]})
  sudo pacman -Syu --needed --noconfirm "${Packages[@]}" \
    || die "Pacman can not install the packages $_"
  # configure .xinitrc to start desktop session on startup
  if ! grep "\-${system_desktop}" $HOME/.xinitrc; then
    echo "# Here ${system_desktop} is the default
session=\${1:-${system_desktop}}

case \$session in
    ${system_desktop}         ) exec ${startcommand_xinitrc};;
    # No known session, try to run it as command
    *                 ) exec \$1;;
esac
" >> $HOME/.xinitrc \
      || die "can not set ${system_desktop} desktop in ~/.xinitrc"
  fi
  ## How to customize a new desktop on first boot?
  # With a startup script that just need two steps:
  #  * Create a script3.sh with your customizations
  #  * Create script3.desktop entry to autostart script3.sh at first boot
  # create autostart dir and desktop entry
  if [[ "${system_desktop}" == 'openbox' ]]; then
    autostart_path=$HOME/.config/openbox
  else
    autostart_path=$HOME/.config/autostart
  fi
  mkdir -p "${autostart_path}"/ || die " can not create dir $_"
  [[ "${system_desktop}" == 'xfce' ]] && cmd='xfce4-terminal -e'
  # [[ "${system_desktop}" == 'openbox' ]] && cmd='xterm -rv -hold -e'
  [[ "${system_desktop}" == 'openbox' ]] && cmd='xterm -rv'
  [[ "${system_desktop}" == 'cinnamon' ]] && cmd='gnome-terminal --'
  if [[ "${system_desktop}" == 'openbox' ]]; then
   echo "# Programs that will run after Openbox has started
${cmd} &" > "${autostart_path}"/autostart \
     || die "can not create $_ file"
  else
    echo "[Desktop Entry]
Type=Application
Name=setup-desktop-on-first-startup
Comment[C]=Script to config a new Desktop on first boot
Terminal=true
Exec=${cmd} \"bash -c \\\"bash \$HOME/Projects/archlinux/desktop/${system_desktop}/script3.sh; exec bash\\\"\"
X-GNOME-Autostart-enabled=true
NoDisplay=false
" > "${autostart_path}"/script3.desktop || die "can not create $_"
  fi
  unset cmd
  unset autostart_path
fi


## show final message and exit
echo "$0 successful" && sleep 3 && exit


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
