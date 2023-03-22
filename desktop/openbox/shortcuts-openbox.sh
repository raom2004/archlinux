#!/bin/bash
#
# ./shorcuts-openbox.sh
#  customize key shorcuts for openbox with terminal commands
#
### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING ###########
# shopt -o noclobber # file overwriting (>) only if forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if command fails
# set -o nounset     # EXIT if try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # TRACE & EXPAND what gets executed


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


############################################################
#### CODE: #################################################
############################################################

### create rc.xml from scratch?
# Why not just copy the template and change only what we really need!
# create a new file from template
# rc_file=~/.config/openbox/rc.xml || die
tmp_rc_file=/tmp/rc.xml || die
cp /etc/xdg/openbox/rc.xml "${tmp_rc_file}" || die
# remove unnecessary lines:
#  * Keybindings for window switching with the arrow key, lines 279-300
#  * Keybindings for running applications, lines 301-311
sed -i '280,310d' "${tmp_rc_file}" || die

## a template to modify fie content using sed
#
# if cat "${tmp_rc_file}" | grep 'find'; then
#     sed -i 's|find|replace|g' "${tmp_rc_file}"
#     cat "${tmp_rc_file}" | grep 'replace'
# fi

## set working desktops names
# if ! cat "${tmp_rc_file}" | grep -q '<name>1</name>'; then
#     sed -i "/\ \ <names>/a \ \ \ \ <name>1</name>" "${tmp_rc_file}"
#     sed -i "/ \ \ \ <name>1<.*/a \ \ \ \ <name>2</name> " "${tmp_rc_file}"
#     sed -i "/ \ \ \ <name>2<.*/a \ \ \ \ <name>3</name> " "${tmp_rc_file}"
#     sed -i "/ \ \ \ <name>3<.*/a \ \ \ \ <name>4</name> " "${tmp_rc_file}"
# fi

## strength window movement between desktops
# if cat "${tmp_rc_file}" | grep '<strength>10<'; then
#     sed -i 's|<strength>10<|<strength>200<|g' "${tmp_rc_file}" || die
#     cat "${tmp_rc_file}" | grep '<strength>' || die
# fi
# if cat "${tmp_rc_file}" | grep '<screen_edge_strength>20<'; then
#     sed -i 's|<screen_edge_strength>20<|<screen_edge_strength>200<|g' "${tmp_rc_file}" || die
#     cat "${tmp_rc_file}" | grep '<strength>' || die
# fi

############################################################
## set key bindings to change desktop: like in x monad
#  final result:
#   W-1: change to desktop 1
#   W-2: change to desktop 2
#   W-3: change to desktop 3
#   W-4: change to desktop 4

## set keybinding W-F- to only W-
# if cat "${tmp_rc_file}" | grep '<keybind key="W-F'; then
#     sed -i 's|<keybind key="W-F|<keybind key="W-|g' "${tmp_rc_file}" || die
#     cat "${tmp_rc_file}" | grep '<keybind key="W-' || die
# fi

## set key bindings to move windows between desktops: like in xmonad
#  final result:
#   S-W-1: move window to desktop 1
#   S-W-2: move window to desktop 2
#   S-W-3: move window to desktop 3
#   S-W-4: move window to desktop 4

# original: S-A-Left replace: S-A-1
if cat "${tmp_rc_file}" | grep '<keybind key="S-A-Left">'; then
    sed -i 's|<keybind key="S-A-Left">|<keybind key="S-A-1">|g' "${tmp_rc_file}" || die
    cat "${tmp_rc_file}" | grep '<keybind key="S-A-1">' || die
fi
if cat "${tmp_rc_file}" | grep '<action name="SendToDesktop"><to>left</to><wrap>no</wrap></action>'; then
    sed -i 's|<action name="SendToDesktop"><to>left</to><wrap>no</wrap></action>|<action name="SendToDesktop"><to>1</to><wrap>no</wrap></action>|g' "${tmp_rc_file}" || die
    cat "${tmp_rc_file}" | grep '<action name="SendToDesktop"><to>1</to><wrap>no</wrap></action>' || die
fi

# original: S-A-Right replace: S-A-2
if cat "${tmp_rc_file}" | grep '<keybind key="S-A-Right">'; then
    sed -i 's|<keybind key="S-A-Right">|<keybind key="S-A-2">|g' "${tmp_rc_file}" || die
    cat "${tmp_rc_file}" | grep '<keybind key="S-A-2">' || die
fi
if cat "${tmp_rc_file}" | grep '<action name="SendToDesktop"><to>right</to><wrap>no</wrap></action>'; then
    sed -i 's|<action name="SendToDesktop"><to>right</to><wrap>no</wrap></action>|<action name="SendToDesktop"><to>2</to><wrap>no</wrap></action>|g' "${tmp_rc_file}" || die
    cat "${tmp_rc_file}" | grep '<action name="SendToDesktop"><to>2</to><wrap>no</wrap></action>' || die
fi

# original: S-A-Up replace: S-A-3
if cat "${tmp_rc_file}" | grep '<keybind key="S-A-Up">'; then
    sed -i 's|<keybind key="S-A-Up">|<keybind key="S-A-3">|g' "${tmp_rc_file}" || die
    cat "${tmp_rc_file}" | grep '<keybind key="S-A-3">' || die
fi
if cat "${tmp_rc_file}" | grep '<action name="SendToDesktop"><to>up</to><wrap>no</wrap></action>'; then
    sed -i 's|<action name="SendToDesktop"><to>up</to><wrap>no</wrap></action>|<action name="SendToDesktop"><to>3</to><wrap>no</wrap></action>|g' "${tmp_rc_file}" || die
    cat "${tmp_rc_file}" | grep '<action name="SendToDesktop"><to>3</to><wrap>no</wrap></action>' || die
fi

# original: 'S-A-Down' replace: 'S-A-4'
if cat "${tmp_rc_file}" | grep '<keybind key="S-A-Down">'; then
    sed -i 's|<keybind key="S-A-Down">|<keybind key="S-A-4">|g' "${tmp_rc_file}" || die
    cat "${tmp_rc_file}" | grep '<keybind key="S-A-4">' || die
fi
if cat "${tmp_rc_file}" | grep '<action name="SendToDesktop"><to>down</to><wrap>no</wrap></action>'; then
    sed -i 's|<action name="SendToDesktop"><to>down</to><wrap>no</wrap></action>|<action name="SendToDesktop"><to>4</to><wrap>no</wrap></action>|g' "${tmp_rc_file}" || die
    cat "${tmp_rc_file}" | grep '<action name="SendToDesktop"><to>4</to><wrap>no</wrap></action>' || die
fi

# set key binding 'S-A-' to 'S-W-'
if cat "${tmp_rc_file}" | grep '<keybind key="S-A-'; then
    sed -i 's|<keybind key="S-A-|<keybind key="S-W-|g' \
	"${tmp_rc_file}" || die
    cat "${tmp_rc_file}" | grep '<keybind key="S-W-' || die
fi
############################################################

#~ Deprecated
###~ add custom keybinding after the clote tag </keyboard>
# last_xml_tag_keyboard="$(cat "${tmp_rc_file}" | sed -n '/<\/keyboard>/=')"

############################################################
###~ global custom keybindings
#
# 1/2 we will create our custom openbox key bindings in xml tags
# and store it in a file called
echo '' > /tmp/add.txt  || die
# 2/2 we will insert such code in the "${tmp_rc_file}"
# after the line: <!-- Keybindings for running applications -->
#
# WARNING: in shell commands use '&amp;' instead of '&'
############################################################

## OPENBOX custom Key bindings
# Openbox
echo '  <!-- openbox key bindings -->
  <keybind key="S-A-r">
    <action name="Reconfigure">
      <command>openbox --reconfigure</command>
    </action>
  </keybind>' >> /tmp/add.txt || die
# screenshot
echo '  <!-- screenshot key bindings -->
  <keybind key="C-A-s">
    <action name="Execute">
      <command>sh -c "nemo $HOME/Pictures/screenshots"</command>
    </action>
  </keybind>
  <keybind key="W-s">
    <action name="Execute">
      <command>screenshot</command>
    </action>
  </keybind>' >> /tmp/add.txt || die
############################################################
## KEYBINDINGS FOR RUNNING APPLICATIONS
# Image editor
echo '  <!-- screenshot key bindings -->
  <keybind key="W-g">
    <action name="Execute">
      <command>gimp</command>
    </action>
  </keybind>' >> /tmp/add.txt || die

# Webbrowser
echo '
<!-- Keybindings for running applications -->
  <!-- run webbrowser -->
  <keybind key="W-r">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Firefox</name>
      </startupnotify>
      <command>firefox</command>
    </action>
  </keybind>
  <keybind key="W-t">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Firefox-Private</name>
      </startupnotify>
      <command>firefox --private-window</command>
    </action>
  </keybind>
' >> /tmp/add.txt || die

# Emacs
echo '  <!-- emacs key bindings -->
  <keybind key="A-C-0">
    <action name="Execute">
      <command>emacs -q -l ~/Projects/dot-emacs/init-essentials.el ~/Projects/dot-emacs/init-essentials.el</command>
    </action>
  </keybind>
  <keybind key="A-C-1">
    <action name="Execute">
      <command>emacs -q -l ~/Projects/dot-emacs/init-openbox.el ~/Projects/dot-emacs/init-openbox.el</command>
    </action>
  </keybind>
  <keybind key="A-C-2">
    <action name="Execute">
      <command>emacsclient -c ~/Projects/archlinux/desktop/openbox/shortcuts-openbox.sh</command>
    </action>
  </keybind>
  <keybind key="A-C-3">
    <action name="Execute">
      <command>emacsclient -c ~/Projects/archlinux/openbox/autostart</command>
    </action>
  </keybind>
  <keybind key="A-C-4">
    <action name="Execute">
      <command>emacsclient -c ~/.config/openbox/rc.xml</command>
    </action>
  </keybind>
  <keybind key="A-C-5">
    <action name="Execute">
    </action>
      <command>emacsclient -c ~/.config/openbox/menu.xml</command>
  </keybind>
  <keybind key="A-C-6">
    <action name="Execute">
      <command>emacs -q -l ~/Projects/dot-emacs/init-essentials.el ~/Projects/dot-emacs/src-org/init-essentials.org</command>
    </action>
  </keybind>
  <keybind key="A-C-7">
    <action name="Execute">
      <command>emacsclient -c ~/Projects/dot-emacs/init-essentials.el</command>
    </action>
  </keybind>
  <keybind key="A-C-8">
    <action name="Execute">
      <command>emacsclient -c ~/Projects/dot-emacs/src-org/init-essentials.org</command>
    </action>
  </keybind>' >> /tmp/add.txt || die

# Terminal
echo '  <!-- terminal key bindings -->
  <keybind key="A-C-b">
    <action name="Execute">
      <command>sh -c "xterm_custom \"/tmp\" right"</command>
    </action>
  </keybind>
  <keybind key="A-C-n">
    <action name="Execute">
      <command>sh -c "xterm_custom \"$HOME/Projects/archlinux\" right"</command>
    </action>
  </keybind>
  <keybind key="A-C-m">
    <action name="Execute">
      <command>sh -c "xterm_custom \"$HOME/Projects/dot-emacs\" right"</command>
    </action>
  </keybind>
' >> /tmp/add.txt || die

# Musik Player
echo '  <!-- start and stop musik program -->
  <keybind key="W-a">
    <action name="Execute">
      <command>sh -c "pkill audacious || audacious --show-main-window --play"</command>
    </action>
  </keybind>' >> /tmp/add.txt || die

# File manager
echo '
<!-- open file manager-->
<keybind key="W-b">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>file manager bottom left</name>
      </startupnotify>
      <command>sh -c "thunar $HOME/Projects; rasize two_third_upper_left"</command>
    </action>
</keybind>
<keybind key="W-n">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>file manager upper middle</name>
      </startupnotify>
      <command>sh -c "thunar $HOME/Projects/archlinux; rasize two_third_upper_middle"</command>
    </action>
</keybind>
<keybind key="W-m">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>file manager upper right</name>
      </startupnotify>
      <command>sh -c "thunar $HOME/Projects/dot-emacs; rasize two_third_upper_right"</command>
    </action>
</keybind>
' >> /tmp/add.txt

# Program Launchers
echo '  <!--  program launcher key bindings -->
  <keybind key="W-S-p">
    <action name="Execute">
      <name>Run App</name>
      <command>gmrun</command>
    </action>
  </keybind>
  <keybind key="W-p">
    <action name="Execute">
      <name>Run App with ARGUMENTS</name>
      <command>dmenu_run</command>
    </action>
  </keybind>
  <keybind key="W-o">
    <action name="Execute">
      <name>obs</name>
      <command>obs</command>
    </action>
  </keybind>' >> /tmp/add.txt || die

############################################################
# Power System 
echo '  <!--  power system keybindings -->
  <keybind key="C-A-BackSpace">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Reboot</name>
      </startupnotify>
      <command>sh -c "ps | grep audacious &amp;> /dev/null &amp;&amp; audacious --pause | pkill audacious; ps | grep emacs &amp;> /dev/null &amp;&amp; pkill emacs; systemctl reboot"</command>
    </action>
  </keybind>
  <keybind key="C-A-Delete">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Reboot</name>
      </startupnotify>
      <command>sh -c "ps | grep audacious &amp;> /dev/null &amp;&amp; audacious --pause | pkill audacious; ps | grep emacs &amp;> /dev/null &amp;&amp; pkill emacs; systemctl reboot"</command>
    </action>
  </keybind>
  <keybind key="W-S-BackSpace">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Poweroff</name>
      </startupnotify>
      <command>sh -c "ps | grep audacious &amp;> /dev/null &amp;&amp; audacious --pause | pkill audacious; ps | grep emacs &amp;> /dev/null &amp;&amp; pkill emacs; systemctl poweroff"</command>
    </action>
  </keybind>
  <!-- <keybind key="W-S-XF86Eject"> -->
  <keybind key="W-S-Delete">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Poweroff</name>
      </startupnotify>
      <command>sh -c "ps | grep audacious &amp;> /dev/null &amp;&amp; audacious --pause | pkill audacious; ps | grep emacs &amp;> /dev/null &amp;&amp; pkill emacs; systemctl poweroff"</command>
    </action>
  </keybind>
  <keybind key="W-S-q">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>restart openbox WITHOUT reboot</name>
      </startupnotify>
      <command>sh -c "bash ~/Projects/archlinux/desktop/openbox/shortcuts-openbox.sh; openbox --restart"</command>
    </action>
  </keybind>
  <keybind key="W-q">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>restart openbox and reboot</name>
      </startupnotify>
      <command>sh -c "bash ~/Projects/archlinux/desktop/openbox/shortcuts-openbox.sh; ps | grep audacious &amp;> /dev/null &amp;&amp; audacious --pause | pkill audacious; ps | grep emacs &amp;> /dev/null &amp;&amp; pkill emacs; killall -SIGUSR1 tint2; openbox --exit"</command>
    </action>
  </keybind>' >> /tmp/add.txt || die

############################################################
## keyboard language
## deprecated for command in .xinitrc
# echo ' <!-- switch keyboard language -->
#   <keybind key="W-F1">
#     <action name="Execute">
#       <startupnotify>
#         <enabled>true</enabled>
#         <name>setxkbmap -query | grep es$ &amp;&amp; setxkbmap us || setxkbmap es</name>
#       </startupnotify>
#       <command></command>
#     </action>
#   </keybind>' >> /tmp/add.txt
############################################################
## Media Control : Sound
echo '  <keybind key="XF86AudioRaiseVolume">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Volume up</name>
      </startupnotify>
      <command>amixer set Master 2%+</command>
    </action>
  </keybind>
  <keybind key="XF86AudioLowerVolume">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Volume down</name>
      </startupnotify>
      <command>amixer set Master 2%-</command>
    </action>
  </keybind>
  <keybind key="XF86AudioMute">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Mute</name>
      </startupnotify>
      <command>amixer set Master toggle</command>
    </action>
  </keybind>
  <keybind key="XF86AudioPlay">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>playback</name>
      </startupnotify>
      <command>audtool playback-playpause</command>
    </action>
  </keybind>
  <keybind key="XF86AudioStop">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Stop playback</name>
      </startupnotify>
      <command>audtool playback-stop</command>
    </action>
  </keybind>
  <keybind key="XF86AudioPrev">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>playback-reverse</name>
      </startupnotify>
      <command>audtool playlist-reverse</command>
    </action>
  </keybind>
  <keybind key="XF86AudioNext">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>playback-advance</name>
      </startupnotify>
      <command>audtool playlist-advance</command>
    </action>
  </keybind>' >> /tmp/add.txt || die

## WARNING: set fallback key binding when keyboard has no media keys
# set key binding to sound volume up:        W-S-Right 
# set key binding to sound volume down:      W-S-Left 
# set key binding to play and pause:         S-Delete 
echo '  <!-- sound control key bindings -->
  <keybind key="W-S-Right">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Volume up</name>
      </startupnotify>
      <command>amixer set Master 5%+</command>
    </action>
  </keybind>
  <keybind key="W-S-Left">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Volume down</name>
      </startupnotify>
      <command>amixer set Master 5%-</command>
    </action>
  </keybind>
  <keybind key="W-Insert">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Stop playback</name>
      </startupnotify>
      <command>audtool playback-stop</command>
    </action>
  </keybind>
  <keybind key="W-Delete">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>playback</name>
      </startupnotify>
      <command>audtool playback-playpause</command>
    </action>
  </keybind>
  <keybind key="W-Prior">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>playback-reverse</name>
      </startupnotify>
      <command>audtool playlist-reverse</command>
    </action>
  </keybind>
  <keybind key="W-Next">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>playback-advance</name>
      </startupnotify>
      <command>audtool playlist-advance</command>
    </action>
  </keybind>' >> /tmp/add.txt || die

############################################################
## Screen Backlight
# 
# if grep -i apple /sys/devices/virtual/dmi/id/board_vendor
## screen backlight
echo '<!-- screen backlight key bindings -->
  <keybind key="XF86MonBrightnessUp">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>backlight up</name>
      </startupnotify>
      <command>backlight -dinc</command>
    </action>
  </keybind>
  <keybind key="XF86MonBrightnessDown">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>backlight down</name>
      </startupnotify>
      <command>backlight -ddec</command>
    </action>
  </keybind>' >> /tmp/add.txt || die

############################################################
## keyboard backlight key bindings 
echo '<!-- keyboard backlight key bindings -->
  <keybind key="XF86KbdBrightnessUp">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>backlight up</name>
      </startupnotify>
      <command>backlight -kinc</command>
    </action>
  </keybind>
  <keybind key="XF86XbdBrightnessDown">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>backlight up</name>
      </startupnotify>
      <command>backlight -kdec</command>
    </action>
  </keybind>' >> /tmp/add.txt || die


############################################################
### WINDOW CONTROL
############################################################
## Window Maximize keybindings using wmctrl
echo '<!-- Window maximize keybindings using wmctrl -->
  <keybind key="C-F11">
      <action name="ToggleMaximize">
        <direction>horizontal</direction>
      </action>
  </keybind>
  <keybind key="A-F11">
      <action name="ToggleMaximize">
        <direction>vertical</direction>
      </action>
  </keybind>
' >> /tmp/add.txt

## Window Movement key bindings tiling or snapping
echo '<!-- Window Movement key bindings tiling or snapping -->
  <keybind key="W-Up">
    <action name="If">
      <query>
        <maximized>yes</maximized>
      </query>
      <then>
        <action name="ToggleMaximize"/>
      </then>
      <else>
        <action name="Execute">
          <command>moveresize_window -l up</command>
        </action>
      </else>
    </action>
  </keybind>
  <keybind key="W-Down">
    <action name="Execute">
      <command>moveresize_window -l bottom</command>
    </action>
  </keybind>
  <keybind key="W-Left">
    <action name="Execute">
      <command>moveresize_window -l left</command>
    </action>
  </keybind>
  <keybind key="W-Right">
    <action name="Execute">
      <command>moveresize_window -l right</command>
    </action>
  </keybind>
' >> /tmp/add.txt || die

## Window Movement key bindings in a grid of 3x3: Symmetric
echo '<!-- Window Movement key bindings in a grid of 3x3: Symmetric -->
<keybind key="W-F1">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling upper left</name>
      </startupnotify>
      <command>moveresize_window -l one_third_upper_left</command>
    </action>
</keybind>
<keybind key="W-F2">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling upper middle</name>
      </startupnotify>
      <command>moveresize_window -l one_third_upper_middle</command>
    </action>
</keybind>
<keybind key="W-F3">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling upper right</name>
      </startupnotify>
      <command>moveresize_window -l one_third_upper_right</command>
    </action>
</keybind>
<keybind key="W-F4">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling center left</name>
      </startupnotify>
      <command>moveresize_window -l one_third_center_left</command>
    </action>
</keybind>
<keybind key="W-F5">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling center middle</name>
      </startupnotify>
      <command>moveresize_window -l one_third_center_middle</command>
    </action>
</keybind>
<keybind key="W-F6">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling center right</name>
      </startupnotify>
      <command>moveresize_window -l one_third_center_right</command>
    </action>
</keybind>
<keybind key="W-F7">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling bottom left</name>
      </startupnotify>
      <command>moveresize_window -l one_third_bottom_left</command>
    </action>
</keybind>
<keybind key="W-F8">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling bottom middle</name>
      </startupnotify>
      <command>moveresize_window -l one_third_bottom_middle</command>
    </action>
</keybind>
<keybind key="W-F9">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling bottom right</name>
      </startupnotify>
      <command>moveresize_window -l one_third_bottom_right</command>
    </action>
</keybind>
<keybind key="W-F10">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling double left</name>
      </startupnotify>
      <command>moveresize_window -l two_third_upper_left</command>
    </action>
</keybind>
<keybind key="W-F11">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling double middle</name>
      </startupnotify>
      <command>moveresize_window -l two_third_upper_middle</command>
    </action>
</keybind>
<keybind key="W-F12">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling double right</name>
      </startupnotify>
      <command>moveresize_window -l two_third_upper_right</command>
    </action>
</keybind>
' >> /tmp/add.txt

## Window Movement key bindings in a grid of 2x2: Symmetric
echo '<!-- Window Movement key bindings in a grid of 2x2: Symmetric -->
<keybind key="W-1">
  <action name="Execute">
    <command>moveresize_window -l upper_left</command>
  </action>
</keybind>
<keybind key="W-2">
  <action name="Execute">
    <command>moveresize_window -l upper_right</command>
  </action>
</keybind>
<keybind key="W-3">
  <action name="Execute">
    <command>moveresize_window -l bottom_left</command>
  </action>
</keybind>
<keybind key="W-4">
  <action name="Execute">
    <command>moveresize_window -l bottom_right</command>
  </action>
</keybind>
' >> /tmp/add.txt

## Window Movement key bindings in a grid of 3x3: ASYMMETRIC
echo '<!-- Window Movement key bindings in a grid of 3x3: ASYMMETRIC -->
<keybind key="W-5">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>double upper left</name>
      </startupnotify>
      <command>moveresize_window -l asym_double_upper_left</command>
    </action>
</keybind>
<keybind key="W-6">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>double bottom left</name>
      </startupnotify>
      <command>moveresize_window -l asym_double_bottom_left</command>
    </action>
</keybind>
<keybind key="W-7">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling upper left</name>
      </startupnotify>
      <command>moveresize_window -l asym_upper_left</command>
    </action>
</keybind>
<keybind key="W-8">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling upper right</name>
      </startupnotify>
      <command>moveresize_window -l asym_upper_right</command>
    </action>
</keybind>
<keybind key="W-9">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling bottom left</name>
      </startupnotify>
      <command>moveresize_window -l asym_bottom_left</command>
    </action>
</keybind>
<keybind key="W-0">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>tiling bottom right</name>
      </startupnotify>
      <command>moveresize_window -l asym_bottom_right</command>
    </action>
</keybind>
' >> /tmp/add.txt

## add code to file
sed -i '/<!-- Keybindings for window switching with the arrow keys -->/r /tmp/add.txt' "${tmp_rc_file}" || die

## delete unnecessary line
sed -i '279,280d' "${tmp_rc_file}" || die

## delete unnecessary lines about W-F{1..4} keybindings
sed -i '220,231d' "${tmp_rc_file}" || die

## backup ~/.config/openbox/rc.xml in ~/Projects/backup/conf-files only if necessary
cp -v --update --backup=numbered ~/.config/openbox/rc.xml ~/Projects/backup/conf-files || die
## update ~/.config/openbox/rc.xml with tmp_rc_file only if they are different
#   or the file is not present
cp --verbose --update "${tmp_rc_file}" ~/.config/openbox || die

# the alternative is to use the backup custom function:
# copy_and_backup -v -f "${tmp_rc_file}" -o ~/.config/openbox

