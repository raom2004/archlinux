#!/bin/bash
#
# alternate between keyboard layouts
#
# Dependencies: pulseaudio
check_keymap="$(setxkbmap -query | awk '/layout/{ print $2 }')"
case "$check_keymap" in
    es)
	setxkbmap us
	break
	;;
    us)
	setxkbmap es
	break
	;;
esac
unset check_keymap
