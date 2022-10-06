#!/bin/bash
#
# alternate between keyboard layouts
#
# Dependencies: pulseaudio
lang="$(setxkbmap -query | awk '/layout/{ print $2 }')"
case "${lang}" in
    es)
	setxkbmap us
	notify-send Layout US
	;;
    us)
	setxkbmap es
	notify-send Layout DE
	;;
esac
unset lang

# lang=$(setxkbmap -query | grep layout | sed 's/layout.* //g')

# if [[ $lang == "de" ]]
# then
#     setxkbmap us
#     notify-send Layout US
# elif [[ $lang == "us" ]]
# then
#     setxkbmap de
#     notify-send Layout DE
# fi

