#!/bin/bash
#
# xfce_config.sh script set xfce4 customized config qith xfconf-query


### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING ###################

# shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


# install desktop and sound control
if [[ ! -n "$(pacman -Qs xfce4)" ]]; then
  sudo pacman -Sy --needed --noconfirm \
       xorg-server xterm \
       xfce4 xfce4-pulseaudio-plugin \
       pavucontrol pavucontrol-qt
fi

### run desktop creating the dotfiles ".xinitrc" and ".serverrc":
# source: https://wiki.archlinux.org/title/Xinit#xinitrc

## .xinitrc 
# create xinitrc from template
head -n50 /etc/X11/xinit/xinitrc > $HOME/.xinitrc
# set keymap
mykeymap="$(localectl | awk 'tolower($0) ~ /keymap/{ printf $3 }')"
echo "setxkbmap ${mykeymap}" >> $HOME/.xinitrc
unset mykeymap
# start xfce but let place to add other desktops in the future 
echo '# Here Xfce is kept as default
session=${1:-xfce}

case $session in
    xfce|xfce4        ) exec startxfce4;;
    # No known session, try to run it as command
    *                 ) exec $1;;
esac
' >> $HOME/.xinitrc
# run application during desktop startup
echo 'sh -c "sleep 3 && emacs"' >> $HOME/.xinitrc

# IMPORTANT: run xinitrc as normal user
# chown "${USER}:${USER}" /home/*/.xinitrc


## .serverrc
# In order to maintain an authenticated session with logind and to
# prevent bypassing the screen locker by switching terminals,
# it is recommended to specify vt$XDG_VTNR in the ~/.xserverrc file: 
echo '#!/bin/sh

exec /usr/bin/Xorg -nolisten tcp -nolisten local "$@" vt$XDG_VTNR
' > $HOME/.xserverrc


echo '[Unit]
Description=Config xfce
Wants=NetworkManager-wait-online.service
After=NetworkManager-wait-online.service
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/env bash $HOME/Projects/archlinux-desktop-xfce/setup-xfce.sh
[Install]
WantedBy=default.target' > ~/.config/systemd/user/setup-xfce.service


## now you can run the desktop with
# startx


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:
