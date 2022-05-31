#!/bin/bash
#
# search for an alternative audio output connection and select it
#
# Dependencies: pulseaudio
audio_output="$(pacmd list-sinks \
    | grep -e 'index:' -e 'name:' \
    | pcregrep -M "[^\*] index.*\n.*name:" \
    | awk -F"[<>]" ' { printf $2 }')"
pactl set-default-sink "${audio_output}"
