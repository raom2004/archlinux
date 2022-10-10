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


### DECLARE FUNCTIONS


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
# Purpose: ERROR HANDLING
# Requirements: None
########################################
## ERROR HANDLING
function out     { printf "$1 $2\n" "${@:3}"; }
# function error   { out "==> ERROR:" "$@"; } >&2
# if error: show file of origin, line number and function
function error   {
  local file="${BASH_SOURCE[1]}"
  local line="${BASH_LINENO[1]}"
  local func="${FUNCNAME[2]}"
  local description="$(sed -n "${line}p" "${file}")"
  out "==> ERROR:" "${file}: line ${line}:"
  msg2 "code: ${description}" 
} >&2
function die     { error "$@"; exit 1; }
## MESSAGES
function warning { out "==> WARNING:" "$@"; } >&2
function msg     { out "==>" "$@"; }
function msg2    { out "  ->" "$@";}

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
fi' >> "${file}"
    fi
  done
}

### TIME CONFIGURATION 

ln -sf /usr/share/zoneinfo"${local_time}" /etc/localtime \
  || die
hwclock --systohc || die


### LANGUAGE CONFIGURATION (support for us, gb, dk, es, de)

sed -i 's/#\(en_US.UTF-8\)/\1/' /etc/locale.gen || die
sed -i 's/#\(en_GB.UTF-8\)/\1/' /etc/locale.gen || die
sed -i 's/#\(en_DK.UTF-8\)/\1/' /etc/locale.gen || die
sed -i 's/#\(es_ES.UTF-8\)/\1/' /etc/locale.gen || die
sed -i 's/#\(de_DE.UTF-8\)/\1/' /etc/locale.gen || die
locale-gen || die
echo 'LANG=en_US.UTF-8'        >  /etc/locale.conf || die
echo 'LANGUAGE=en_US:en_GB:en' >> /etc/locale.conf || die
echo 'LC_COLLATE=C'            >> /etc/locale.conf || die
echo 'LC_MESSAGES=en_US.UTF-8' >> /etc/locale.conf || die
echo 'LC_TIME=en_DK.UTF-8'     >> /etc/locale.conf || die
# Keyboard Configuration (e.g. set spanish as keyboard layout)
# localectl set-keymap --no-convert es # do not work under chroot
# if [[ "${system_desktop:-}" == 'openbox' ]]; then
#   localectl --no-convert set-x11-keymap es,us,de pc105 \
# 	    grp:win_space_toggle \
#     || die
# else
  echo "KEYMAP=${keyboard_keymap}" > /etc/vconsole.conf \
    || die
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
url="https://gist.githubusercontent.com/anonymous/8eb2019db2e278ba99be/raw/257f15100fd46aeeb8e33a7629b209d0a14b9975/gistfile1.sh"
wget "${url}" -O /etc/grub.d/31_hold_shift || die
chmod a+x /etc/grub.d/31_hold_shift || die
## Config a boot loader GRUB
grub-mkconfig -o /boot/grub/grub.cfg || die


### ACCOUNTS CONFIG

## sudo requires to turn on "wheel" groups
sed -i 's/# \(%wheel ALL=(ALL:ALL) ALL\)/\1/g' /etc/sudoers \
  || die
## set root password
echo -e "${root_password}\n${root_password}" | (passwd root) \
  || die
## create new user and set ZSH as shell
useradd -m "${user_name}" -s "${user_shell}" \
  || die
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
if [[ "${MACHINE}" == 'VBox' ]]; then
   systemctl enable vboxservice || die
fi


### TTY AUTOLOGING AT STARTUP

mkdir -p /etc/systemd/system/getty@tty1.service.d \
  || die
printf "[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${user_name} --noclear %%I $TERM
" > /etc/systemd/system/getty@tty1.service.d/autologin.conf \
  || die


### CUSTOMIZE SHELL

## support for command not found
pacman -S --needed --noconfirm pkgfile \
  || die
pkgfile -u || die


### TOUCHPAD

## package synaptics
pacman -S --needed --noconfirm xf86-input-synaptics
# wc -l /usr/share/X11/xorg.conf.d/70-synaptics.conf # lines: 46
# configure tap as click, including this code after line 13
head -n13 /usr/share/X11/xorg.conf.d/70-synaptics.conf \
 > /tmp/70-synaptics.conf
echo '        Option "TapButton1" "1"
        Option "TapButton2" "2"
        Option "TapButton3" "3"' >> /tmp/70-synaptics.conf
# copy the rest of the code (46 - 13 = rest 33 lines)        
tail -n33 /usr/share/X11/xorg.conf.d/70-synaptics.conf \
 >> /tmp/70-synaptics.conf
mv /tmp/70-synaptics.conf \
   /usr/share/X11/xorg.conf.d/70-synaptics.conf


### SCREEN AND KEYBOARD BACKLICHT SCRIPTS
screen_kernel_path=$(ls /sys/class/backlight/*_backlight/../)
screen_kernel=/sys/class/backlight/"${screen_kernel_path}"

touch /usr/local/bin/backlight
   
echo "#!/bin/bash

set -e

screen=\$(ls ${screen_kernel}/brightness)
screen_current=\$(cat \${screen})
screen_max=\$(cat ${screen_kernel}/max_brightness)
# screen_value: is a % value used to increase or decrease brightness
# it is a percentage calculated using the max brightness
# its value is 5%, but can also be set using an arg $2 between 1-100
screen_value=\$(((screen_max * \${2:-5}) / 100))
" >> /usr/local/bin/backlight

if ls /sys/class/leds/*kbd_backlight/../ &>2; then
  keyboard_kernel_path=$(ls /sys/class/leds/*kbd_backlight/../)
  keyboard_kernel=/sys/class/leds/"${keyboard_kernel_path}"
  echo "
keyboard=\$(ls ${keyboard_kernel:-}/brightness)
key_current=\$(cat "${keyboard}")
key_max=\$(cat ${keyboard_kernel:-}/max_brightness)
# key_value: is a % value used to increase or decrease brightness
# it is a percentage calculated using the max brightness
# its value is 10%, but can also be set using an arg $2 between 1-100
key_value=\$(((key_max * \${2:-25}) / 100))
" >> /usr/local/bin/backlight
fi

echo "case \$1 in
    -dinc|--display-increase)
        echo \"\$((screen_current + screen_value > screen_max ? screen_max : screen_current + screen_value))\" > \$screen
	;;

    -ddec|--display-decrease)
        echo \"\$((screen_current < screen_value ? 0 : screen_current - screen_value))\" > \$screen
	;;
" >> /usr/local/bin/backlight

if ls /sys/class/leds/*kbd_backlight/../ &>2; then
  echo "
    -kinc|--keyboard-increase)
        value=\"\$((key_current + key_value > key_max ? key_max : key_current + key_value))\"
    brightnessctl --device=\"${keyboard_kernel_path}\" set \"\${value}\" &>2
    unset value
	;;

    -kdec|--keyboard-increase)
    value=\"\$((key_current < key_value ? 0 : key_current - key_value))\"
    brightnessctl --device=\"${keyboard_kernel_path}\" set \"\${value}\" &>2
    unset value
	;;
" >> /usr/local/bin/backlight
fi

echo "    -h|--help)
        echo -e \"\$0 increase or decreace screen and keyboard backlight:
    Usage:
     -dinc <n>    \"increase display brightness (0-100%)\"
     -ddec <n>    \"decrease display brightness (0-100%)\"
     -kinc <n>    \"increase keyboard led brightness (0-100%)\"
     -kdec <n>    \"decrease keyboard led brightness (0-100%)\"

    *<n> is optional, when not provided, standard value will be:
     - screen 5%
     - keyboard 10%

    Example:
      $ $0 -kinc
       -> this command will increment screen brightness in 5%
      $ $0 -kinc 20
       -> this command will increment screen brightness in 20%
\"
	;;
    ,*)
        echo -e \"Unknown option try -h or --help\";;
esac" >> /usr/local/bin/backlight
chmod +x /usr/local/bin/backlight

## generate a udev rule to allow screen backline work to non root users
mkdir -p /etc/udev/rules.d
echo "KERNEL==\"${screen_kernel_path}\", \
SUBSYSTEM==\"backlight\", \
RUN+=\"/usr/bin/find ${screen_kernel}/ -type f -name brightness -exec chown ${user_name}:${user_name} {} ; -exec chmod 666 {} ;\"" > /etc/udev/rules.d/30-brightness.rules


### USER SYSTEM CUSTOMIZATION ########################################

## set environment variables
HOME=/home/"${user_name}"

## Autostart X at login
# only if Desktop or Window Manager will be installed


if [[ "${install_desktop}" =~ ^([yY])$ ]]; then
  autostart_x_at_login
fi


## create $USER dirs (LC_ALL=C, means everything in English)
pacman -S --needed --noconfirm xdg-user-dirs \
  || die
LC_ALL=C xdg-user-dirs-update --force \
  || die

## Overriding system locale per $USER session
mkdir -p $HOME/.config || die
echo 'LANG=es_ES.UTF-8'         > $HOME/.config/locale.conf \
  || die
echo 'LANGUAGE=en_GB:en_US:en' >> $HOME/.config/locale.conf \
  || die

## create dotfiles ".xinitrc" and ".serverrc"
#   * source: https://wiki.archlinux.org/title/Xinit#xinitrc
# ~/.xinitrc: create from template
head -n50 /etc/X11/xinit/xinitrc > $HOME/.xinitrc \
  || die
# set keyboard keymap in .xinitrc
available_layouts=("${keyboard_keymap}")
[[ ! "${available_layouts[*]}" =~ es ]] && available_layouts+=('es')
[[ ! "${available_layouts[*]}" =~ at ]] && available_layouts+=('at')
[[ ! "${available_layouts[*]}" =~ us ]] && available_layouts+=('us')
echo "setxkbmap -model pc105 -layout ${available_layouts},us,at -option grp:win_space_toggle" >> $HOME/.xinitrc || die
unset available_layouts || die
# add filemanager dependency to xinitrc
echo 'udiskie &' >> $HOME/.xinitrc || die
## if user asked to install a desktop
# configure .xinitrc to start desktop session on startup
if [[ "${install_desktop}" =~ ^([yY])$ ]]; then
  if ! grep "\-${system_desktop}" $HOME/.xinitrc; then
    echo "# Here ${system_desktop} is the default
session=\${1:-${system_desktop}}

case \$session in
    ${system_desktop}         ) exec ${startcommand_xinitrc};;
    # No known session, try to run it as command
    *                 ) exec \$1;;
esac
" >> $HOME/.xinitrc || die
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
  mkdir -p "${autostart_path}"/ || die
  [[ "${system_desktop}" == 'xfce' ]] && cmd='xfce4-terminal -e'
  # [[ "${system_desktop}" == 'openbox' ]] && cmd='xterm -rv -hold -e'
  [[ "${system_desktop}" == 'openbox' ]] && cmd="xterm -rv -fa 'Ubuntu Mono' -fs 14"
  [[ "${system_desktop}" == 'cinnamon' ]] && cmd='gnome-terminal --'
  if [[ "${system_desktop}" == 'openbox' ]]; then
   echo "# Programs that will run after Openbox has started
${cmd} -e \"bash -c \\\"bash \$HOME/Projects/archlinux/desktop/${system_desktop}/script3.sh; exec bash\\\"\" &
" > "${autostart_path}"/autostart || die
  else
    echo "[Desktop Entry]
Type=Application
Name=setup-desktop-on-first-startup
Comment[C]=Script to config a new Desktop on first boot
Terminal=true
Exec=${cmd} \"bash -c \\\"bash \$HOME/Projects/archlinux/desktop/${system_desktop}/script3.sh; exec bash\\\"\"
X-GNOME-Autostart-enabled=true
NoDisplay=false
" > "${autostart_path}"/script3.desktop || die
  fi
  unset cmd
  unset autostart_path
fi
# ~/.serverrc
# In order to maintain an authenticated session with logind and to
# prevent bypassing the screen locker by switching terminals,
# it is recommended to specify vt$XDG_VTNR in the ~/.xserverrc file: 
echo '#!/bin/sh
exec /usr/bin/Xorg -nolisten tcp -nolisten local "$@" vt$XDG_VTNR
' > $HOME/.xserverrc


### INSTALL DEPENDECIES

## Vim Plugin Manager
url=https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
wget "${url}" -P $HOME/.vim/autoload \
  || die
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
# decompressing language tools
cd $HOME/Downloads || die
extract "$(basename "${url}")" || die
[[ -d "$(basename "${url}" .zip)" ]] \
  && rm "$(basename "${url}")" \
    || die
cd $PWD || die


## show final message and exit
echo "$0 successful" && sleep 3 && exit


# emacs:
# Local Variables:
# sh-basic-offset: 2
# End:

# vim: set ts=2 sw=2 et:
