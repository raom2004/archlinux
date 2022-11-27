#!/bin/bash
#
# ./script2.sh configure a new Arch Linux system
#
# Summary:
# * Customize a new Arch Linux system, inside arch-chroot.
# * Create a desktop autostart app to run the scrip3.sh on first boot
#   to make the user desktop custmizations related. 
#
# Dependencies: ./script1.sh
#
### CODE:

### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING

# shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)


### DECLARE FUNCTIONS


########################################
# Purpose: ERROR HANDLING
# Requirements: None
########################################

## ERROR HANDLING
function out     { printf "$1 $2\n" "${@:3}"; }
# function error   { out "==> ERROR:" "$@"; } >&2
# function die     { error "$@"; exit 1; }
function die {
  # if error, exit and show file of origin, line number and function
  # colors
  NO_FORMAT="\033[0m"
  C_RED="\033[38;5;9m"
  C_YEL="\033[38;5;226m"
  # color functions
  function msg_red { printf "${C_RED}${@}${NO_FORMAT}"; }
  function msg_yel { printf "${C_YEL}${@}${NO_FORMAT}"; }
  # error detailed message (colored)
  msg_red "==> ERROR: " && printf " %s" "$@" && printf "\n"
  msg_yel "  -> file: " && printf "${BASH_SOURCE[1]}\n"
  msg_yel "  -> func: " && printf "${FUNCNAME[2]}\n"
  msg_yel "  -> line: " && printf "${BASH_LINENO[1]}\n"
  exit 1
}

## MESSAGES
function warning { out "==> WARNING:" "$@"; } >&2
function msg     { out "==>" "$@"; }
function msg2    { out "  ->" "$@"; }


########################################
# Purpose: extract compressed files
# Requirements: None
########################################

function extract {
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2)   tar xvjf "$1"    ;;
      *.tar.gz)    tar xvzf "$1"    ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar x "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xvf "$1"     ;;
      *.tbz2)      tar xvjf "$1"    ;;
      *.tgz)       tar xvzf "$1"    ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *)           echo "don't know how to extract '$1'..." ;;
    esac
  else
    echo "'$1' is not a valid file!"
  fi
}


########################################
# Purpose: autostart x at login
# Requirements: None
########################################

function autostart_x_at_login {
  for file in ~/.{bash_profile,zprofile}; do
    if [[ -f "${file}" ]]; then
      echo '
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
  exec startx
fi' >> "${file}" || die
    fi
  done
}


### Requirements: check priviledges


if [[ "$EUID" -ne 0 ]]; then
  echo "error: run ./$0 require root priviledges" || die
  exit
fi


### TIME CONFIGURATION 


ln -sf /usr/share/zoneinfo"${local_time}" /etc/localtime || die
hwclock --systohc || die


### LANGUAGE CONFIGURATION


## generate LOCALE with support for: us, gb, dk, es, de
sed -i 's/#\(en_US.UTF-8\)/\1/' /etc/locale.gen || die
sed -i 's/#\(en_GB.UTF-8\)/\1/' /etc/locale.gen || die
sed -i 's/#\(en_DK.UTF-8\)/\1/' /etc/locale.gen || die
sed -i 's/#\(es_ES.UTF-8\)/\1/' /etc/locale.gen || die
sed -i 's/#\(de_DE.UTF-8\)/\1/' /etc/locale.gen || die
locale-gen || die

## Set SYSTEM LOCALE
# WARNING: some programms name english as "C" instead of "en" or "en_US"
# set default locale
echo 'LANG=en_GB.UTF-8'          >  /etc/locale.conf || die
# set fallback locales when the first option is not available
echo 'LANGUAGE=en_GB:en_US:en:C' >> /etc/locale.conf || die
# set how sorting and regular expressions works
echo 'LC_COLLATE=C'              >> /etc/locale.conf || die
# set specific language to display messages
echo 'LC_MESSAGES=C' >> /etc/locale.conf || die
# set the formatting used for time and date
echo 'LC_TIME=en_DK.UTF-8'       >> /etc/locale.conf || die

## TTY Keyboard Configuration (e.g. set spanish as keyboard layout)
# localectl set-keymap --no-convert es # do not work under chroot
# if [[ "${system_desktop:-}" == 'openbox' ]]; then
#   localectl --no-convert set-x11-keymap es,us,de pc105 \
# 	    grp:win_space_toggle \
#     || die
# else
echo "KEYMAP=${keyboard_keymap}" > /etc/vconsole.conf || die
# fi


### Network Configuration


echo "${host_name}" > /etc/hostname || die
echo "127.0.0.1	localhost
::1		localhost
127.0.1.1	${host_name}.localdomain	${host_name}
" >> /etc/hosts || die


### INIT RAM FILSESYSTEM: initramfs


## Initramfs was run for pacstrap but must be run for LVM, encryp or USB
# support to boot in removable media (USB stick)
# if [[ "${drive_removable}" == 'yes' ]]; then
#   sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev block keyboard autodetect modconf filesystems fsck)/' /etc/mkinitcpio.conf \
#     && msg2 "setting HOOKS for removable drive ${drive_removable}" \
#       || die
#   mkinitcpio -P && msg2 "success mkinitcpio" || die
# fi


### BOOT LOADER (GRUB) CONFIG

## Install boot loader GRUB
# if [[ "${drive_removable}" == 'no' ]]; then
# grub-install --target=i386-pc "${target_device}" \

# specific for installation git branch ssd
grub-install --target=i386-pc /dev/sdc \
  && msg2 "Installing grub on $_" \
    || die

# else
#   grub-install --target=i386-pc --debug --removable "${target_device}" \
#     && msg2 "Installing grub on $_" \
#       || die
#   mkdir -p /etc/systemd/journald.conf.d/ || die
#   echo '[Journal]
# Storage=volatile
# SystemMaxUse=16M
# RuntimeMaxUse=32M' > /etc/systemd/journald.conf.d/10-volatille.conf \
#        || die
# fi
## set display resolution bigger in virtual machine
# if [[ "${MACHINE}" == 'VBox' ]]; then
#    sed -i 's/\(GRUB_GFX_MODE=\)\(auto\)/\11024x768x32,\2/' \
#       /etc/default/grub || die
# fi

## detect additional kernels or operative systems available
sed -i 's/#\(GRUB_DISABLE_OS_PROBER=false\)/\1/' /etc/default/grub \
  || die

## hide boot loader at startup
echo "GRUB_FORCE_HIDDEN_MENU=true"  >> /etc/default/grub \
  || die

## press shift to show boot loader menu at start up
# download file and name it as: /etc/grub.d/31_hold_shift
url="https://gist.githubusercontent.com/anonymous/8eb2019db2e278ba99be/raw/257f15100fd46aeeb8e33a7629b209d0a14b9975/gistfile1.sh"
wget "${url}" -O /etc/grub.d/31_hold_shift || die
# change the permission of a file for all users
chmod a+x /etc/grub.d/31_hold_shift || die

## Config a boot loader GRUB
grub-mkconfig -o /boot/grub/grub.cfg || die


### ACCOUNTS CONFIG

## sudo requires to turn on "wheel" groups
sed -i 's/# \(%wheel ALL=(ALL:ALL) ALL\)/\1/g' /etc/sudoers || die

## set root password
echo -e "${root_password}\n${root_password}" | (passwd root) || die

## create new user and set ZSH as shell
useradd -m "${user_name}" -s "${user_shell}" || die

## set new user password
echo -e "${user_password}\n${user_password}" | (passwd $user_name) \
  || die

## set user groups
usermod -aG wheel,audio,optical,storage,power,network "${user_name}" \
  || die


### PACMAN PACKAGE MANAGER CUSTOMIZATION

## turn color on
sed -i 's/#\(Color\)/\1/' /etc/pacman.conf || die

## improve compiling time adding processors "nproc"
sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf \
  || die


### START SERVICES ON REBOOT

## enable ethernet and wifi
systemctl enable dhcpcd	|| die
systemctl enable NetworkManager || die

## enable virtualbox if this is a virtual machine
if [[ "${MACHINE}" == 'VBox' ]]; then
   systemctl enable vboxservice || die
fi


### TTY AUTOLOGING AT STARTUP

# create a service to enable autologin
mkdir -p /etc/systemd/system/getty@tty1.service.d || die
printf "[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${user_name} --noclear %%I $TERM
" > /etc/systemd/system/getty@tty1.service.d/autologin.conf || die


### CUSTOMIZE SHELL

## support for command not found
pacman -S --needed --noconfirm pkgfile || die
pkgfile -u || die


### TOUCHPAD

## install touchpad package 'synaptics' and configure it

# requirement
pacman -S --needed --noconfirm xf86-input-synaptics

# generate a temporal file with the configuration of taps as clicks:
# set 1 Tap for left click "1"
echo '        Option "TapButton1" "1"' > /tmp/synaptics
# set 2 Taps for middle click "3"
echo '        Option "TapButton2" "3"' >> /tmp/synaptics
# set 3 Taps for right click "2"
echo '        Option "TapButton3" "2"' >> /tmp/synaptics

# insert temporal file content into the synaptics.conf
#  after the line: MatchIsTouchpad "on"
sed -i '/MatchIsTouchpad "on"/r /tmp/synaptics' \
    /usr/share/X11/xorg.conf.d/70-synaptics.conf || die
        

### SCREEN AND KEYBOARD BACKLICHT SCRIPTS

## script "backlight" to control screen and keyboard
# WARNING: the idea is to use this script with key bindings to:
# XF86MonBrightnessUp or XF86KbdBrightnessUp
# variables required
screen_kernel=$(ls /sys/class/backlight | grep backlight)
screen_kernel_path=/sys/class/backlight/${screen_kernel}
# script "backlight"
echo "#!/bin/bash

set -e

# path of the screen kernel
screen=\$(ls ${screen_kernel_path}/brightness)
screen_current=\$(cat \${screen})
screen_max=\$(cat ${screen_kernel_path}/max_brightness)
# screen_value: is a % value used to increase or decrease brightness
# it is a percentage calculated using the max brightness
# its value is 5%, but can also be set using an arg \$2 between 1-100
screen_value=\$(((screen_max * \${2:-5}) / 100))

# if keyboard HAS backlight, set variables to control it
if ls /sys/class/leds | grep backlight); then
  keyboard_kernel=\$(ls /sys/class/leds | grep backlight)
  keyboard_kernel_path=/sys/class/leds/\${keyboard_kernel}
  keyboard=\$(ls ${keyboard_kernel_path}/brightness)
  key_current=\$(cat \${keyboard})
  key_max=\$(cat \${keyboard_kernel_path}/max_brightness)
  # key_value: is a % value used to increase or decrease brightness
  # it is a percentage calculated using the max brightness
  # its value is 10%, but can also be set using an arg \$2 between 1-100
  key_value=\$(((key_max * \${2:-25}) / 100))
fi

case \$1 in
     
    -dinc|--display-increase)
        echo \"\$((screen_current + screen_value > screen_max ? screen_max : screen_current + screen_value))\" > \$screen
	;;

    -ddec|--display-decrease)
        echo \"\$((screen_current < screen_value ? 0 : screen_current - screen_value))\" > \$screen
	;;

    -kinc|--keyboard-increase)
        value=\"\$((key_current + key_value > key_max ? key_max : key_current + key_value))\"
        brightnessctl --device=\"\${keyboard_kernel}\" set \"\${value}\" >&2
        unset value
	;;

    -kdec|--keyboard-increase)
        value=\"\$((key_current < key_value ? 0 : key_current - key_value))\"
        brightnessctl --device=\"\${keyboard_kernel}\" set \"\${value}\" >&2
    unset value
	;;

    -h|--help)
        echo -e \"\$0 increase or decreace screen and keyboard backlight:
    Usage:
     -dinc <n>    \\\"increase display brightness (0-100%)\\\"
     -ddec <n>    \\\"decrease display brightness (0-100%)\\\"
     -kinc <n>    \\\"increase keyboard led brightness (0-100%)\\\"
     -kdec <n>    \\\"decrease keyboard led brightness (0-100%)\\\"

    ,*<n> is optional, when not provided, standard value will be:
     - screen 5%
     - keyboard 10%

    Example:
      $ $0 -kinc
       -> this command will increment screen brightness in 5%
      $ $0 -kinc 20
       -> this command will increment screen brightness in 20%\"
	;;

    ,*)
        echo -e \"Unknown option try -h or --help\"
        ;;

esac" > /usr/local/bin/backlight
# set execution permission to "backlight"
chmod +x /usr/local/bin/backlight
# create an udev rule to allow script "backline" work to non root users
mkdir -p /etc/udev/rules.d
echo "KERNEL==\"${screen_kernel}\", \
SUBSYSTEM==\"backlight\", \
RUN+=\"/usr/bin/find ${screen_kernel_path}/ -type f -name brightness -exec chown ${user_name}:${user_name} {} ; -exec chmod 666 {} ;\"" > /etc/udev/rules.d/30-brightness.rules
 

### USER SYSTEM CUSTOMIZATION ########################################


## set environment variables
HOME=/home/"${user_name}"

## create $USER dirs (LC_ALL=C, means everything in English)
pacman -S --needed --noconfirm xdg-user-dirs \
  || die
LC_ALL=C xdg-user-dirs-update --force \
  || die

## Overriding system locale per $USER session
mkdir -p $HOME/.config || die
echo 'LANG=es_ES.UTF-8'          > $HOME/.config/locale.conf || die
echo 'LANGUAGE=en_GB:en_US:en:C' >> $HOME/.config/locale.conf || die

## create dotfiles ".xinitrc" and ".serverrc"
#   * source: https://wiki.archlinux.org/title/Xinit#xinitrc
# ~/.xinitrc: create from template
head -n50 /etc/X11/xinit/xinitrc > $HOME/.xinitrc || die
# ~/.serverrc:
# In order to maintain an authenticated session with logind and to
# prevent bypassing the screen locker by switching terminals,
# it is recommended to specify vt$XDG_VTNR in the ~/.xserverrc file: 
echo '#!/bin/sh
exec /usr/bin/Xorg -nolisten tcp -nolisten local "$@" vt$XDG_VTNR
' > $HOME/.xserverrc


## if user asked to install a desktop
if [[ "${install_desktop}" =~ ^([yY])$ ]]; then

  ## set Xorg keyboard keymap and filemanager dependency
  # add to keyboard_keymap support for other keymaps: es, at, us
  available_layouts=("${keyboard_keymap}")
  [[ ! "${available_layouts[*]}" =~ es ]] && available_layouts+=('es')
  [[ ! "${available_layouts[*]}" =~ at ]] && available_layouts+=('at')
  [[ ! "${available_layouts[*]}" =~ us ]] && available_layouts+=('us')
  #~ set keyboard map using /etc/X11/xorg.conf.d
  echo "Section \"InputClass\"
    Identifier \"keyboard defaults\"
    MatchIsKeyboard \"on\"
    Option \"XkbModel\" \"pc105\"
    Option \"XkbLayout\" \"${available_layouts}\"
    Option \"XKbOptions\" \"grp:win_space_toggle\"
EndSection" > /etc/X11/xorg.conf.d/90-custom-kbd.conf || die

  # WARNING: keymap can be set in ~/.xinitrc, but in xmonad that FAILED
  if [[ "${system_desktop}" == 'openbox' ]]; then
    #~ Contrary to linux desktops, in OPENBOX the
    #~ the filemanager dependency can be set in
    #~  ~/.config/openbox/autostart instead of ~/.xinitrc
    mkdir -p $HOME/.config/openbox    
    echo 'udiskie &' >> $HOME/.config/openbox/autostart || die
  else
    # add filemanager dependency to xinitrc
    echo 'udiskie &' >> $HOME/.xinitrc || die
  fi

  ## Autostart X at login
  autostart_x_at_login

  ## configure .xinitrc to start desktop session on startup
  # continue only if .xinitrc NOT HAS a preexistent line:
  #   session=\${1:-${system_desktop}}
  if ! grep "\-${system_desktop}" $HOME/.xinitrc; then
    # append code to .xinitrc to start a session with a system_desktop
    echo "# Here ${system_desktop} is the default
session=\${1:-${system_desktop}}

case \$session in
    ${system_desktop}         ) exec ${startcommand_xinitrc};;
    # Not known session, try to run it as command
    *                 ) exec \$1;;
esac
" >> $HOME/.xinitrc || die
  fi
  ## How to customize a new desktop on first boot?
  # With a startup script that just need two steps:
  #  * Create a script3.sh with your customizations
  #  * Create script3.desktop entry to autostart script3.sh at first boot

  # create autostart dir and desktop entry
  # if [[ "${system_desktop}" == 'openbox' ]]; then
  #   autostart_path=$HOME/.config/openbox
  # else
  #   autostart_path=$HOME/.config/autostart
  # fi
  # mkdir -p "${autostart_path}"/ || die

  # set terminal command 'cmd' for every Desktop or Window Manager
  [[ "${system_desktop}" == 'xfce' ]] && cmd='xfce4-terminal -e'
  [[ "${system_desktop}" == 'cinnamon' ]] && cmd='gnome-terminal --'
  [[ "${system_desktop}" == 'openbox' ]] \
    && cmd="xterm -rv -fa 'Ubuntu Mono' -fs 13 -e "

  case "${system_desktop}" in

    ## AUTOSTART
    # Linux Desktops implement XDG autostarting to start programs on
    # start up, normally creating destop files in a specific location:
    #  ~/config/autostart/
    # 
    # We will use this to call 'script3.sh' creating
    # a desktop file: script3.desktop
    # located in the directory: ~/.config/autostart/
    xfce|cinnamon)
      mkdir -p $HOME/.config/autostart || die
      echo "[Desktop Entry]
Type=Application
Name=setup-desktop-on-first-startup
Comment[C]=Script to config a new Desktop on first boot
Terminal=true
Exec=${cmd} \"bash -c \\\"bash \$HOME/Projects/archlinux/desktop/${system_desktop}/script3.sh; exec bash\\\"\"
X-GNOME-Autostart-enabled=true
NoDisplay=false" > $HOME/.config/autostart/script3.desktop || die
      break
      ;;

    # openbox has its own autostart system:
    # Instead of "~/.config/autostart", openbox uses their own folder:
    #  ~/.config/openbox
    # an a unique fail called 'autostart', to locate the programs:
    #  ~/.config/openbox/autostart
    # WARNING: in OPENBOX autostart is a file, NOT A DIRECTORY
    # call 'script3.sh' adding this line to the autostart file
    openbox)
      echo "# Programs that will run after Openbox has started
${cmd} \"bash -c \\\"bash \$HOME/Projects/archlinux/desktop/openbox/script3.sh; exec bash\\\"\" &
" > $HOME/.config/openbox/autostart || die
  # unset available_layouts || die  

      # support for keyboard
      # instead of ~/.xinitrc, we will add keyboard config
      # using the autostart file:
      # echo "setxkbmap -model pc105 -layout ${available_layouts},us,at -option grp:win_space_toggle" >> $HOME/.config/openbox/autostart || die
      break
      ;;
  esac
  
  # unset unnecessary variables 
  [[ ! -z "${cmd}" ]] && unset cmd
  # [[ ! -z "${autostart_path}" ]] && unset autostart_path
fi


### INSTALL DEPENDECIES

## Vim Plugin Manager
url=https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
wget "${url}" -P $HOME/.vim/autoload || die
## TODO: install vim plugins without open vim (must not be run as root)
# vim -E -s -u $HOME/.vimrc +PlugInstall +visual +qall
unset url || die

## add dictionaty of english medical terms for hunspell
# source: https://github.com/Glutanimate/hunspell-en-med-glut

url=https://raw.githubusercontent.com/glutanimate/hunspell-en-med-glut/master/en_med_glut.dic
wget "${url}" -P /usr/share/hunspell || die
unset url || die


### INSTALL EMACS DEPENDENCIES

## support for ditaa graphs - emacs org

url=https://github.com/stathissideris/ditaa/blob/master/service/web/lib/ditaa0_10.jar || die
wget "${url}" -P $HOME/Downloads || die

## support for language tools

url=https://languagetool.org/download/
latest_version=$(wget -O - "${url}" \
			       | awk -F'"' '/[0-9]\.zip/{ print $2 }' \
			       | sort -r \
			       | head -n1 \
			       | tr -d '\n')
url=https://languagetool.org/download/"${latest_version}"
wget "${url}" -P $HOME/Downloads || die
unset latest_version

## decompressing language tools

cd $HOME/Downloads || die
extract "$(basename "${url}")" || die
[[ -d "$(basename "${url}" .zip)" ]] && rm "$(basename "${url}")" || die
cd $PWD || die


### INSTALL OPENBOX FROM GIT REPO AND ADD SNAP FEATURE

# git clone https://github.com/lawl/opensnap || die
# cd opensnap || die
# make || die
# make install || die
git clone https://github.com/danakj/openbox || die
cp openbox-window-snap.diff openbox || die
cd openbox || die
git apply openbox-window-snap.diff || die
./bootstrap
make || die
make install || die

### show final message and exit

echo "$0 successful" && sleep 3 && exit


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
