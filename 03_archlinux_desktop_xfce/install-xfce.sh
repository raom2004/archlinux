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
# if [[ ! -n "$(pacman -Qs xfce4)" ]]; then

## update complete system packages

sudo pacman -Syu --noconfirm

## install graphical user interface (display server with nvidia support)

sudo pacman -Sy --needed --noconfirm xorg-{server,xrandr} xterm

# alternatives: xorg-xinit xorg-clock

## install desktop packages

sudo pacman -Sy --needed --noconfirm \
     xfce4 \
     xfce4-{pulseaudio-plugin,screenshooter} \
     pavucontrol pavucontrol-qt \
     papirus-icon-theme

## install web browser

sudo pacman -Sy --needed --noconfirm firefox

## install packages for wider support of glyphs and fonts  

sudo pacman -Sy --needed --noconfirm \
     ttf-{hanazono,font-awesome,ubuntu-font-family}

## package to identify system manufacture

sudo pacman -Sy --needed --noconfirm dmidecode

### INSTALL PACKAGES ACCORDING TO SYSTEM (REAL VS VIRTUALIZED) #######

## Check if archlinux install run in VIRTUAL or REAL system
check_actual_system="$(sudo dmidecode -s system-manufacturer)"

# If VIRTUAL system, install virtualbox support:
if [[ "${check_actual_system}" != "innotek GmbH" ]]; then
  sudo pacman -Sy --needed --noconfirm virtualbox-guest-utils
fi

# packages for hardware functionallity
sudo pacman -Sy --needed --noconfirm linux-firmware
# multi-OS support packages
sudo pacman -Sy --needed --noconfirm \
	   usbutils \
	   dosfstools ntfs-3g amd-ucode intel-ucode
# heavy code editor packages
sudo pacman -Sy --needed --noconfirm emacs


### run desktop creating the dotfiles ".xinitrc" and ".serverrc":
# source: https://wiki.archlinux.org/title/Xinit#xinitrc

## ~/.xinitrc
# create a new ~/.xinitrc from template
head -n50 /etc/X11/xinit/xinitrc > $HOME/.xinitrc
# set keymap
desktop_keymap="$(localectl | awk 'tolower($0) ~ /keymap/{ printf $3 }')"
echo "setxkbmap ${mykeymap}" >> $HOME/.xinitrc
unset desktop_keymap
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
# echo 'sh -c "sleep 3 && emacs"' >> $HOME/.xinitrc

# IMPORTANT: run xinitrc as normal user
# chown "${USER}:${USER}" "$HOME/.xinitrc"


## ~/.serverrc
# In order to maintain an authenticated session with logind and to
# prevent bypassing the screen locker by switching terminals,
# it is recommended to specify vt$XDG_VTNR in the ~/.xserverrc file: 
echo '#!/bin/sh

exec /usr/bin/Xorg -nolisten tcp -nolisten local "$@" vt$XDG_VTNR
' > $HOME/.xserverrc


# sudo bash -c "echo '[Unit]
# Description=Config xfce
# Wants=network-online.target
# After=network-online.target
# # Wants=NetworkManager-wait-online.service
# # After=NetworkManager-wait-online.service
# [Service]
# Type=oneshot
# RemainAfterExit=yes
# ExecStart=/usr/bin/xfce4-terminal
# # -e $HOME/Projects/archlinux-desktop-xfce/setup-xfce.sh
# [Install]
# WantedBy=default.target' > /etc/systemd/system/my.service"
# sudo systemctl enable my.service

## TODO1: test new way
# source: https://bbs.archlinux.org/viewtopic.php?id=247292

# mkdir -p ~/.config/systemd/user/
# echo '[Unit]
# Description=User Graphical Login
# Requires=default.target
# After=default.target
# ' > ~/.config/systemd/user/user-graphical-login.target

# mkdir -p ~/.local/bin/scripts/
# echo '#!/usr/bin/env bash
# systemctl --user import-environment
# systemctl --user start user-graphical-login.target
# ' > ~/.local/bin/scripts/import_env.sh

# echo "[Unit]
# Description=Start tmux in detached session
# Requires=user-graphical-login.target
# After=user-graphical-login.target

# [Service]
# Type=forking
# ExecStart=/usr/bin/tmux new-session -s '%u-init' -d;
# ExecStop=/usr/bin/tmux kill-session -t '%u-init'

# [Install]
# WantedBy=user-graphical-login.target
# " > ~/.config/systemd/user/tmux@.service

## setup desktop xfce by autostart desktop entry
# source: https://bbs.archlinux.org/viewtopic.php?id=247292
# xdg directories
# source: https://wiki.archlinux.org/title/XDG_Base_Directory

mkdir -p $HOME/.config/autostart
echo '[Desktop Entry]
Type=Application
Encoding=UTF-8
Version=1.0
Name=script3
Comment[C]=Script for basic config of xfce4 Desktop
Comment[es]=Script para la configuración básica del escritório xfce4
Exec=/usr/bin/gnome-terminal -- bash -c "sh ${HOME}/Projects/archlinux-desktop-xfce/include/setup-xfce.sh;exec bash"
Terminal=true
X-GNOME-Autostart-enabled=true
NoDisplay=false' > $HOME/.config/autostart/setup-xfce.desktop

# echo '[Desktop Entry]
# Type=Application
# Encoding=UTF-8
# Version=1.0
# Name=script3
# Comment[C]=Script for basic config of xfce4 Desktop
# Comment[es]=Script para la configuración básica del escritório xfce4
# Exec=bash -c "sh ${HOME}/Projects/archlinux-desktop-xfce/include/setup-xfce.sh;exec bash"
# Terminal=true
# X-GNOME-Autostart-enabled=true
# NoDisplay=false' > $HOME/.config/autostart/script3.desktop

echo "[Desktop Entry]
Type=Application
Encoding=UTF-8
Version=1.0
Name=emacs
Comment[C]=Script for basic config of emacs
Comment[es]=Script para la configuración básica de emacs
Exec=emacs -q -l --eval \"(progn (load-theme 'misterioso)(set-cursor-color \\\"turquoise\\\"))\"
# Terminal=true
X-GNOME-Autostart-enabled=true
NoDisplay=false" > $HOME/.config/autostart/emacs.desktop


# if the other fail you can try by user instead of admin
# ~/.config/systemd/user/setup-xfce.service


## now you can run the desktop with
# startx


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:
