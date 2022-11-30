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
cp /etc/xdg/openbox/rc.xml ~/.config/openbox/rc.xml || die
# remove unnecessary lines:
#  * Keybindings for window switching with the arrow key, lines 279-300
#  * Keybindings for running applications, lines 301-3011
sed -i '280,310d' ~/.config/openbox/rc.xml || die

## a template to modify fie content using sed
#
# if cat "${rc_file}" | grep 'find'; then
#     sed -i 's|find|replace|g' "${rc_file}"
#     cat "${rc_file}" | grep 'replace'
# fi
#
#
## set global file name
rc_file=~/.config/openbox/rc.xml || die
## set working desktops names
# if ! cat "${rc_file}" | grep -q '<name>1</name>'; then
#     sed -i "/\ \ <names>/a \ \ \ \ <name>1</name>" "${rc_file}"
#     sed -i "/ \ \ \ <name>1<.*/a \ \ \ \ <name>2</name> " "${rc_file}"
#     sed -i "/ \ \ \ <name>2<.*/a \ \ \ \ <name>3</name> " "${rc_file}"
#     sed -i "/ \ \ \ <name>3<.*/a \ \ \ \ <name>4</name> " "${rc_file}"
# fi

## strength window movement between desktops
# if cat "${rc_file}" | grep '<strength>10<'; then
#     sed -i 's|<strength>10<|<strength>200<|g' "${rc_file}" || die
#     cat "${rc_file}" | grep '<strength>' || die
# fi
if cat "${rc_file}" | grep '<screen_edge_strength>20<'; then
    sed -i 's|<screen_edge_strength>20<|<screen_edge_strength>200<|g' "${rc_file}" || die
    cat "${rc_file}" | grep '<strength>' || die
fi
############################################################
## set key bindings to change desktop: like in x monad
#  final result:
#   W-1: change to desktop 1
#   W-2: change to desktop 2
#   W-3: change to desktop 3
#   W-4: change to desktop 4
#
## set keybinding W-F- to only W-
if cat "${rc_file}" | grep '<keybind key="W-F'; then
    sed -i 's|<keybind key="W-F|<keybind key="W-|g' "${rc_file}" || die
    cat "${rc_file}" | grep '<keybind key="W-' || die
fi

## set key bindings to move windows between desktops: like in xmonad
#  final result:
#   S-W-1: move window to desktop 1
#   S-W-2: move window to desktop 2
#   S-W-3: move window to desktop 3
#   S-W-4: move window to desktop 4
#
# original: S-A-Left replace: S-A-1
if cat "${rc_file}" | grep '<keybind key="S-A-Left">'; then
    sed -i 's|<keybind key="S-A-Left">|<keybind key="S-A-1">|g' "${rc_file}" || die
    cat "${rc_file}" | grep '<keybind key="S-A-1">' || die
fi
if cat "${rc_file}" | grep '<action name="SendToDesktop"><to>left</to><wrap>no</wrap></action>'; then
    sed -i 's|<action name="SendToDesktop"><to>left</to><wrap>no</wrap></action>|<action name="SendToDesktop"><to>1</to><wrap>no</wrap></action>|g' "${rc_file}" || die
    cat "${rc_file}" | grep '<action name="SendToDesktop"><to>1</to><wrap>no</wrap></action>' || die
fi
# original: S-A-Right replace: S-A-2
if cat "${rc_file}" | grep '<keybind key="S-A-Right">'; then
    sed -i 's|<keybind key="S-A-Right">|<keybind key="S-A-2">|g' "${rc_file}" || die
    cat "${rc_file}" | grep '<keybind key="S-A-2">' || die
fi
if cat "${rc_file}" | grep '<action name="SendToDesktop"><to>right</to><wrap>no</wrap></action>'; then
    sed -i 's|<action name="SendToDesktop"><to>right</to><wrap>no</wrap></action>|<action name="SendToDesktop"><to>2</to><wrap>no</wrap></action>|g' "${rc_file}" || die
    cat "${rc_file}" | grep '<action name="SendToDesktop"><to>2</to><wrap>no</wrap></action>' || die
fi
# original: S-A-Up replace: S-A-3
if cat "${rc_file}" | grep '<keybind key="S-A-Up">'; then
    sed -i 's|<keybind key="S-A-Up">|<keybind key="S-A-3">|g' "${rc_file}" || die
    cat "${rc_file}" | grep '<keybind key="S-A-3">' || die
fi
if cat "${rc_file}" | grep '<action name="SendToDesktop"><to>up</to><wrap>no</wrap></action>'; then
    sed -i 's|<action name="SendToDesktop"><to>up</to><wrap>no</wrap></action>|<action name="SendToDesktop"><to>3</to><wrap>no</wrap></action>|g' "${rc_file}" || die
    cat "${rc_file}" | grep '<action name="SendToDesktop"><to>3</to><wrap>no</wrap></action>' || die
fi
# original: 'S-A-Down' replace: 'S-A-4'
if cat "${rc_file}" | grep '<keybind key="S-A-Down">'; then
    sed -i 's|<keybind key="S-A-Down">|<keybind key="S-A-4">|g' "${rc_file}" || die
    cat "${rc_file}" | grep '<keybind key="S-A-4">' || die
fi
if cat "${rc_file}" | grep '<action name="SendToDesktop"><to>down</to><wrap>no</wrap></action>'; then
    sed -i 's|<action name="SendToDesktop"><to>down</to><wrap>no</wrap></action>|<action name="SendToDesktop"><to>4</to><wrap>no</wrap></action>|g' "${rc_file}" || die
    cat "${rc_file}" | grep '<action name="SendToDesktop"><to>4</to><wrap>no</wrap></action>' || die
fi
# set key binding 'S-A-' to 'S-W-'
if cat "${rc_file}" | grep '<keybind key="S-A-'; then
    sed -i 's|<keybind key="S-A-|<keybind key="S-W-|g' \
	"${rc_file}" || die
    cat "${rc_file}" | grep '<keybind key="S-W-' || die
fi
############################################################



#~ Deprecated
###~ add custom keybinding after the clote tag </keyboard>
# last_xml_tag_keyboard="$(cat ~/.config/openbox/rc.xml | sed -n '/<\/keyboard>/=')"



############################################################
###~ global custom keybindings
#
# 1/2 we will create our custom openbox key bindings in xml tags
# and store it in a file called
echo '' > /tmp/add.txt  || die
# 2/2 we will insert such code in the ~/.config/openbox/rc.xml
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
  <keybind key="W-s">
    <action name="Execute">
      <command>sh -c "gnome-screenshot -cf /tmp/screenshot &amp;&amp; cat /tmp/screenshot | xclip -i -selection clipboard -target image/png; gimp /tmp/screenshot"</command>
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
  <keybind key="A-C-1">
    <action name="Execute">
      <command>emacs -q -l ~/Projects/dot-emacs/init-essentials.el ~/.emacs.d/init-essentials.el</command>
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
  <keybind key="A-C-m">
    <action name="Execute">
      <command>xterm -rv -fa "Ubuntu Mono" -fs 13</command>
    </action>
  </keybind>' >> /tmp/add.txt || die
# Musik Player
echo '  <!-- start and stop musik program -->
  <keybind key="W-a">
    <action name="Execute">
      <command>sh -c "pkill audacious || audacious --show-main-window --play"</command>
    </action>
  </keybind>' >> /tmp/add.txt || die
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
  </keybind>' >> /tmp/add.txt || die
############################################################
# Power System 
echo '  <!--  power system keybindings -->
  <keybind key="C-A-Delete">
    <action name="Execute">
      <startupnotify>
        <enabled>true</enabled>
        <name>Poweroff</name>
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
        <name>reboot</name>
      </startupnotify>
      <command>sh -c "bash ~/Projects/archlinux/desktop/openbox/shortcuts-openbox.sh; openbox --restart"</command>
    </action>
  </keybind>
  <keybind key="W-q">
    <action name="Execute">
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
' >> /tmp/add.txt || die

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
        <name>backlight up</name>
      </startupnotify>
      <command>backlight -ddec</command>
    </action>
  </keybind>' >> /tmp/add.txt || die

## WARNING: set fallback key binding when keyboard has no backlight keys
# set key binding to screen backlight up:    W-S-Up 
# set key binding to screen backlight down:  W-S-Down 
# echo '  <!-- backlight key bindings -->
#   <keybind key="W-S-Down">
#     <action name="Execute">
#       <startupnotify>
#         <enabled>true</enabled>
#         <name>light down</name>
#       </startupnotify>
#       <command>backlight -ddec</command>
#     </action>
#   </keybind>
#   <keybind key="W-S-Up">
#     <action name="Execute">
#       <startupnotify>
#         <enabled>true</enabled>
#         <name>light up</name>
#       </startupnotify>
#       <command>backlight -dinc</command>
#     </action>
#   </keybind>
# ' >> /tmp/add.txt || die

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


# ## worked
# echo '
#   <keybind key="W-Up">
#     <action name="If">
#       <query>
#         <maximizedhorizontal>no</maximizedhorizontal>
#       </query>
#       <then>
#         <action name="ToggleMaximizeHorz"/>
#       </then>
#       <else>
#         <action name="ToggleMaximize"/>
#       </else>
#     </action>
#   </keybind>
#   <keybind key="W-Left">
#         <action name="ToggleMaximizeVert"/>
#   </keybind>
# ' >> /tmp/add.txt

## worked
echo '
  <keybind key="W-Up">
    <action name="If">
      <query>
        <maximizedhorizontal>no</maximizedhorizontal>
      </query>
      <then>
        <action name="ToggleMaximizeHorz"/>
      </then>
      <else>
        <action name="ToggleMaximize"/>
      </else>
    </action>
  </keybind>
  <keybind key="W-Left">
        <action name="ToggleMaximizeVert"/>
  </keybind>' >> /tmp/add.txt || die


## TODO: testing code from maximize.c


## worked
# echo '
#   <keybind key="W-Up">        # HalfLeftScreen
#     <action name="If">
#       <query>
#         <maximized>yes</maximized>
#       </query>
#       <then>
#         <action name="Unmaximize"/>
#       </then>
#       <else>
#         <action name="ToggleMaximize">
#           <direction>vertical</direction>
#         </action>
#       </else>
#     </action>
#   </keybind>
# ' >> /tmp/add.txt

## worked
# echo '
#   <keybind key="W-Up">        # HalfLeftScreen
#     <action name="If">
#       <query>
#         <maximized>yes</maximized>
#       </query>
#       <then>
#         <action name="Unmaximize"/>
#       </then>
#       <else>
#         <action name="ToggleMaximize"/>
#       </else>
#     </action>
#   </keybind>
# ' >> /tmp/add.txt

# echo '
# <!-- Window Tiling: Emulates Windows 7 Snap feature -->
# <keybind key="W-Left">        # HalfLeftScreen
#     <action name="UnmaximizeFull"/>
#     <action name="MoveResizeTo"><x>0</x><y>0</y><height>100%</height><width>50%</width></action>
# </keybind>
# ' >> /tmp/add.txt

# ## testing superman (1)
# # source: https://github.com/CasualSuperman/OpenboxSnap/blob/master/rc.xml
# # worked pretty good
# echo '
# <!-- up -->
#     <keybind key="W-Up">
#       <action name="If">
#         <maximizedhorizontal>no</maximizedhorizontal>
#         <maximizedvertical>no</maximizedvertical>
#         <then>
#           <action name="ToggleMaximize">
#             <direction>horizontal</direction>
#           </action>
#           <action name="MoveResizeTo">
#             <x>0</x>
#             <y>0</y>
#             <height>50%</height>
#           </action>
#         </then>
#         <else>
#           <action name="Unmaximize"/>
#           <action name="MoveResizeTo">
#             <x>center</x>
#             <y>center</y>
#             <width>50%</width>
#             <height>50%</height>
#           </action>
#         </else>
#       </action>
#     </keybind>
# <!-- down -->
#     <keybind key="W-Down">
#       <action name="If">
#         <maximizedhorizontal>no</maximizedhorizontal>
#         <maximizedvertical>no</maximizedvertical>
#         <then>
#           <action name="ToggleMaximize">
#             <direction>horizontal</direction>
#           </action>
#           <action name="MoveResizeTo">
#             <x>0</x>
#             <y>-0</y>
#             <height>50%</height>
#           </action>
#         </then>
#         <else>
#           <action name="Unmaximize"/>
#           <action name="MoveResizeTo">
#             <x>center</x>
#             <y>center</y>
#             <width>50%</width>
#             <height>50%</height>
#           </action>
#         </else>
#       </action>
#     </keybind>
# <!-- left -->
#     <keybind key="W-Left">
#       <action name="If">
#         <maximized>yes</maximized>
#         <then>
#           <action name="ToggleMaximize">
#             <direction>horizontal</direction>
#           </action>
#           <action name="MoveResizeTo">
#             <x>0</x>
#             <width>50%</width>
#           </action>
#         </then>
#         <else>
#           <action name="ToggleMaximize">
#             <direction>vertical</direction>
#           </action>
#           <action name="If">
#             <maximizedvertical>yes</maximizedvertical>
#             <then>
#               <action name="MoveResizeTo">
#                 <x>0</x>
#                 <width>50%</width>
#               </action>
#               <action name="ResizeRelative">
#                 <right>-1</right>
#               </action>
#             </then>
#             <else>
#               <action name="MoveResizeTo">
#                 <x>center</x>
#                 <y>center</y>
#               </action>
#             </else>
#           </action>
#         </else>
#       </action>
#     </keybind>
# <!-- right -->
#     <keybind key="W-Right">
#       <action name="If">
#         <maximized>yes</maximized>
#         <then>
#           <action name="ToggleMaximize">
#             <direction>horizontal</direction>
#           </action>
#           <action name="MoveResizeTo">
#             <x>-0</x>
#             <width>50%</width>
#           </action>
#         </then>
#         <else>
#           <action name="ToggleMaximize">
#             <direction>vertical</direction>
#           </action>
#           <action name="If">
#             <maximizedvertical>yes</maximizedvertical>
#             <then>
#               <action name="MoveResizeTo">
#                 <x>-0</x>
#                 <width>50%</width>
#               </action>
#               <action name="ResizeRelative">
#                 <left>-1</left>
#               </action>
#             </then>
#             <else>
#               <action name="MoveResizeTo">
#                 <x>center</x>
#                 <y>center</y>
#               </action>
#             </else>
#           </action>
#         </else>
#       </action>
#     </keybind>
# ' >> /tmp/add.txt

## window tiling (last try)
# source: https://github.com/emilypeto/openbox-window-snap
# echo '
# <!-- Window Tiling: Emulates Windows 7 Snap feature -->
# <keybind key="W-Left">        # HalfLeftScreen
#   <action name="If">
#     <query target="default">
#       <position><x>0</x></position>
#     </query>
#     <then>
#     </then>
#     <else>
#     </else>
#   </action>
# </keybind>
# ' >> /tmp/add.txt

# echo '
# <keybind key="W-Right">       # HalfRightScreen
#     <action name="UnmaximizeFull"/>
#     <action name="MoveResizeTo"><x>-0</x><y>0</y><height>100%</height><width>50%</width></action>
# </keybind>
# <keybind key="W-Up">          # HalfUpperScreen
#     <action name="UnmaximizeFull"/>
#     <action name="MoveResizeTo"><x>0</x><y>0</y><width>100%</width><height>50%</height></action>
# </keybind>
# ' >> /tmp/add.txt


# https://aur.archlinux.org/packages/opensnap

# ## split tyling (worked)
# echo '
# <keybind key="W-Down">        # HalfLowerScreen
# <!-- Window tiling -->
#     <!-- Switch tiling -->
#       <action name="If">
#         <query target="default">
#           <maximizedvertical>yes</maximizedvertical>
#         </query>
#         <!-- Switch to horizontal -->
#         <then>
#           <action name="UnmaximizeFull"/>
#           <action name="MoveResizeTo">
#             <height>50%</height>
#           </action>
#           <action name="MaximizeHorz"/>
#           <action name="MoveResizeTo">
#             <x>0</x>
#             <y>0</y>
#           </action>
#           <action name="NextWindow">
#             <interactive>no</interactive>
#             <dialog>none</dialog>
#             <finalactions>
#               <action name="UnmaximizeFull"/>
#               <action name="MoveResizeTo">
#                 <height>50%</height>
#               </action>
#               <action name="MaximizeHorz"/>
#               <action name="MoveResizeTo">
#                 <x>0</x>
#                 <y>-0</y>
#               </action>
#             </finalactions>
#           </action>
#         </then>
#         <!-- Switch to vertical -->
#         <else>
#           <action name="UnmaximizeFull"/>
#           <action name="MoveResizeTo">
#             <width>50%</width>
#           </action>
#           <action name="MaximizeVert"/>
#           <action name="MoveResizeTo">
#             <x>0</x>
#             <y>0</y>
#           </action>
#           <action name="NextWindow">
#             <interactive>no</interactive>
#             <dialog>none</dialog>
#             <finalactions>
#               <action name="UnmaximizeFull"/>
#               <action name="MoveResizeTo">
#                 <width>50%</width>
#               </action>
#               <action name="MaximizeVert"/>
#               <action name="MoveResizeTo">
#                 <x>-0</x>
#                 <y>0</y>
#               </action>
#             </finalactions>
#           </action>
#         </else>
#       </action>
#       <!-- Window tiling end -->
# </keybind>
# ' >> /tmp/add.txt

# TODO: oppsions for window snapping in openbox
#
# 1.-very simple: using cpp and sh script 
# source: https://github.com/purpleleaf/openbox-window-snapping


# echo '
#   <keybind key="W-Up">        # HalfLeftScreen
#     <action name="If">
#       <query>
#         <maximizedhorizontal>yes</maximizedhorizontal>
#       </query>
#       <then>
#         <action name="UnmaximizeFull"/>
#       </then>
#       <else>
#         <action name="ToggleMaximize"/>
#       </else>
#     </action>
#   </keybind>
# ' >> /tmp/add.txt

# echo '
#   <keybind key="W-Down">        # HalfLeftScreen
#     <action name="If">
#       <query>
#         <maximizedhorizontal>yes</maximizedhorizontal>
#       </query>
#       <then>
#         <action name="Unmaximize"/>
#       </then>
#       <else>
#         <action name="ToggleMaximize">
#           <direction>horizontal</direction>
#         </action>
#       </else>
#     </action>
#   </keybind>
# ' >> /tmp/add.txt


# echo '
# <keybind key="W-Left">
#     <action name="If">
#       <query>
#         <maximizedvertical>yes</maximizedvertical>
#       </query>
#       <then>
#         <action name="Unmaximize"/>
#         <action name="MoveResizeTo">
#           <width>current</width>
#           <height>current</height>
#         </action>
#       </then>
#       <else>
#         <action name="ToogleMaximize">
#           <direction>vertical</direction>
#         </action>
#         <action name="MoveResizeTo">
#           <x>0</x><y>0</y>
#         </action>
#       </else>
#     </action>
# </keybind>
# ' >> /tmp/add.txt

# echo '<keybind key="W-Right">
#     <action name="If">
#       <query>
#         <maximizedvertical>yes</maximizedvertical>
#       </query>
#       <then>
#         <action name="UnmaximizeFull"/>
#       </then>
#       <else>
#         <action name="MaximizeVert"/>
#         <action name="MoveResizeTo">
#           <x>840</x><y>0</y>
#         </action>
#       </else>
#     </action>
# </keybind>
# ' >> /tmp/add.txt
    

        # <action name="ToggleMaximize">
        #   <direction>vertical</direction>
        # </action>
        # <action name="MoveResizeTo">
        #     <width>50%</width>
        # </action>
        # <action name="MoveToEdge">
        #   <direction>west</direction>
        # </action>


# TODO
# remap key XF86Eject to delete
# xmodmap -pke > ~/.Xmodmap
# complementary material
# KeyRelease event, serial 48, synthetic NO, window 0x600001,
#     root 0x50e, subw 0x0, time 1224776, (639,1024), root:(640,1046),
#     state 0x0, keycode 169 (keysym 0x1008ff2c, XF86Eject), same_screen YES,
#     XLookupString gives 0 bytes: 
#     XFilterEvent returns: False


## old

# window snapping keybindings
#  source:
#   https://wiki.archlinux.org/title/Openbox#Window_snapping
# echo  '  <keybind key="W-Left">
#       <action name="Unmaximize"/>
#       <action name="MaximizeVert"/>
#       <action name="MoveResizeTo">
#           <width>50%</width>
#       </action>
#       <action name="MoveToEdge"><direction>west</direction></action>
#   </keybind>
#   <keybind key="W-Right">
#       <action name="Unmaximize"/>
#       <action name="MaximizeVert"/>
#       <action name="MoveResizeTo">
#           <width>50%</width>
#       </action>
#       <action name="MoveToEdge"><direction>east</direction></action>
#   </keybind>
#   <keybind key="W-Down">
#      <action name="Unmaximize"/>
#   </keybind>
#   <keybind key="W-Up">
#      <action name="Maximize"/>
#   </keybind>' >> /tmp/add.txt

# Window snapping ORIGINAL
# echo  '  <keybind key="W-Left">        # HalfLeftScreen
#     <action name="UnmaximizeFull"/>
#     <action name="MoveResizeTo"><x>0</x><y>0</y><height>100%</height><width>50%</width></action>
# </keybind>
# <keybind key="W-Right">       # HalfRightScreen
#     <action name="UnmaximizeFull"/>
#     <action name="MoveResizeTo"><x>-0</x><y>0</y><height>100%</height><width>50%</width></action>
# </keybind>
# <keybind key="W-Up">          # HalfUpperScreen
#     <action name="UnmaximizeFull"/>
#     <action name="MoveResizeTo"><x>0</x><y>0</y><width>100%</width><height>50%</height></action>
# </keybind>
# <keybind key="W-Down">        # HalfLowerScreen
#     <action name="UnmaximizeFull"/>
#     <action name="MoveResizeTo"><x>0</x><y>-0</y><width>100%</width><height>50%</height></action>
# </keybind>' >> /tmp/add.txt

# # Window snapping customized
# #  source:
# #  http://openbox.org/wiki/Help:Actions#ToggleFullscreen
# # xrandr | awk '/current/{ print $4$5$6}'
# panel_Y_size="$(awk '/panel_size/{print $4}' ~/.config/tint2/tint2rc)"
# Y_complete="$(xdpyinfo | awk '/dimensions/{print $2}' | awk -F'x' '{print $2}')"
# Y_half="$(((Y_complete - panel_Y_size) / 2))"

# echo  "  <keybind key=\"A-F10\">
#     <action name=\"ToggleFullscreen\"/>
#   </keybind>
#   <keybind key=\"W-Left\">        # HalfLeftScreen
#     <action name=\"UnmaximizeFull\"/>
#     <action name=\"MoveResizeTo\"><x>0</x><y>0</y><height>100%</height><width>50%</width></action>
# </keybind>
# <keybind key=\"W-Up\">        # UpperCornerLeftScreen
#     <action name=\"UnmaximizeFull\"/>
#     <action name=\"MoveResizeTo\"><y>0</y><height>50%</height><width>50%</width></action>
# </keybind>
# <keybind key=\"W-Down\">        # UpperCornerLeftScreen
#     <action name=\"UnmaximizeFull\"/>
#     <action name=\"MoveResizeTo\"><y>${Y_half}</y><height>50%</height><width>50%</width></action>
# </keybind>
# <keybind key=\"W-Right\">       # HalfRightScreen
#     <action name=\"UnmaximizeFull\"/>
#     <action name=\"MoveResizeTo\"><x>-0</x><y>0</y><height>100%</height><width>50%</width></action>
# </keybind>
# <!--<keybind key=\"W-Up\">          # HalfUpperScreen
#     <action name=\"UnmaximizeFull\"/>
#     <action name=\"MoveResizeTo\"><x>0</x><y>0</y><width>100%</width><height>50%</height></action>
# </keybind>
# <keybind key=\"W-Down\">        # HalfLowerScreen
#     <action name=\"UnmaximizeFull\"/>
#     <action name=\"MoveResizeTo\"><x>0</x><y>50%</y><width>100%</width><height>50%</height></action>
# </keybind>-->
# " >> /tmp/add.txt

# TODO
# custom widnows snapping (ADVANCE)
#  source:
#https://ideatrash.net/2019/06/organizing-and-tiling-your-windows-on-openbox-using-only-openbox.html

# objective: set window snapping like KDE
# window snapping keybindings
#  source:
#   https://wiki.archlinux.org/title/Openbox#Window_snapping

# echo  '
#   <keybind key="W-Left">        # HalfLeftScreen
#     <action name="Unmaximize"/>
#     <action name="MoveResizeTo"><x>0</x><y>0</y><height>100%</height><width>50%</width></action>
#   </keybind>
#   <keybind key="W-Up">          # HalfUpperScreen
#     <action name="Unmaximize"/>
#     <action name="MoveResizeTo"><x>0</x><y>0</y><width>100%</width><height>50%</height></action>
#   </keybind>
#   <keybind key="W-Right">       # HalfRightScreen
#     <action name="Unmaximize"/>
#     <action name="MoveResizeTo"><x>-0</x><y>0</y><height>100%</height><width>50%</width></action>
#   </keybind>
#   <keybind key="W-Down">        # HalfLowerScreen
#     <action name="Unmaximize"/>
#     <action name="MoveResizeTo"><x>0</x><y>-0</y><width>100%</width><height>50%</height></action>
#   </keybind>
# ' >> /tmp/add.txt

## TODO:
# echo '
#   <keybind key="W-Left">        # HalfLeftScreen
#     <action name="If">
#       <query>
#         <maximizedvertical>yes</maximizedvertical>
#       </query>
#       <then>
#         <action name="Unmaximize"/>
#       </then>
#       <else>
#         <action name="MoveResizeTo">
#           <x>0</x>
#           <y>0</y>
#           <height>100%</height>
#           <width>50%</width>
#         </action>
#       </else>
#     </action>
#   </keybind>
# ' >> /tmp/add.txt

# ## this worked
# echo '
#   <keybind key="W-Left">        # HalfLeftScreen
#     <action name="If">
#       <query>
#         <maximized>yes</maximized>
#       </query>
#       <then>
#         <action name="Unmaximize"/>
#       </then>
#       <else>
#         <action name="ToggleFullScreen"/>
#       </else>
#     </action>
#   </keybind>
# ' >> /tmp/add.txt


## old 2

## work strange
# echo '
#   <keybind key="W-Left">
#     <action name="Unmaximize"/>
#     <action name="MaximizeVert"/>
#     <action name="MoveResizeTo">
#        <width>50%</width>
#     </action>
#     <action name="MoveToEdge"><direction>west</direction></action>
#   </keybind>
#   <keybind key="W-Right">
#     <action name="Unmaximize"/>
#     <action name="MaximizeVert"/>
#     <action name="MoveResizeTo">
#       <width>50%</width>
#     </action>
#     <action name="MoveToEdge"><direction>east</direction></action>
#   </keybind>
#   <keybind key="W-Up">
#     <action name="MoveToEdge"><direction>north</direction></action>
#     <action name="ToggleMaximize"><direction>horizontal</direction></action>
#   </keybind>
#   <keybind key="W-Down">
#     <action name="MoveToEdge"><direction>south</direction></action>
#     <action name="ToggleMaximize"><direction>horizontal</direction></action>
#   </keybind>' >> /tmp/add.txt

# Window snapping ORIGINAL
# echo  '  <keybind key="W-Left">        # HalfLeftScreen
#     <action name="UnmaximizeFull"/>
#     <action name="MoveResizeTo"><x>0</x><y>0</y><height>100%</height><width>50%</width></action>
# </keybind>
# <keybind key="W-Right">       # HalfRightScreen
#     <action name="UnmaximizeFull"/>
#     <action name="MoveResizeTo"><x>-0</x><y>0</y><height>100%</height><width>50%</width></action>
# </keybind>
# <keybind key="W-Up">          # HalfUpperScreen
#     <action name="UnmaximizeFull"/>
#     <action name="MoveResizeTo"><x>0</x><y>0</y><width>100%</width><height>50%</height></action>
# </keybind>
# <keybind key="W-Down">        # HalfLowerScreen
#     <action name="UnmaximizeFull"/>
#     <action name="MoveResizeTo"><x>0</x><y>-0</y><width>100%</width><height>50%</height></action>
# </keybind>' >> /tmp/add.txt

## add code to file
sed -i '/<!-- Keybindings for window switching with the arrow keys -->/r /tmp/add.txt' ~/.config/openbox/rc.xml || die
## delete unnecessary line
sed -i '279,280d' ~/.config/openbox/rc.xml || die
