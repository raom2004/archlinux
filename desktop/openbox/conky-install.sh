sudo pacman -Syu --needed --noconfirm \
     ttf-font-awesome \
     ttf-nerd-fonts-symbols-1000-em-mono \
     ttf-nerd-fonts-symbols-common
     

#~ clear changes
[[ -f ~/.config/conky/conky.conf ]] && rm -rf ~/.config/conky/conky.conf
mkdir -p ~/.config/conky \
    && conky --print-config > ~/.config/conky/conky.conf

#~ CONKY CONFIGURATION

#~ sed example to edit code
# sed -i 's///' ~/.config/conky/conky.conf

#~ set window position

sed -i 's/\(top_\)left/\1right/' ~/.config/conky/conky.conf


#~ set transparency

sed -i 's/\(background = \).*/\1true,/' ~/.config/conky/conky.conf
sed -i '/own_window = true,/a \ \ \ \ own_window_transparent = true,' ~/.config/conky/conky.conf
# sed -i 's/\(double_buffer = \).*/\1yes,/' ~/.config/conky/conky.conf
# sed -i 's/\(own_window = \).*/\1yes,/' ~/.config/conky/conky.conf
# sed -i 's/\(update_interval = \).*/\11.0,/' ~/.config/conky/conky.conf
# sed -i '/background = true,/a \ \ \ \ disable_transparency = 0,' ~/.config/conky/conky.conf
# sed -i '/background = true,/a \ \ \ \ disable_transparency = 0,' ~/.config/conky/conky.conf


#~ delete unnecessary lines

sed -i '52,$ d' ~/.config/conky/conky.conf


#~ set additional font

sed -i "/}/i \ \ \ \ font1 = 'FontAwesome6Free:bold:solid:size=12', " \
    ~/.config/conky/conky.conf


#~ set colors

sed -i "/}/i \ \ \ \ color1 = 'DodgerBlue', " ~/.config/conky/conky.conf
sed -i "/}/i \ \ \ \ color2 = 'lightgrey', " ~/.config/conky/conky.conf
sed -i "/}/i \ \ \ \ color3 = 'ffcb48', " ~/.config/conky/conky.conf
sed -i "/}/i \ \ \ \ color4 = 'red', " ~/.config/conky/conky.conf

#~ set templates

sed -i "/}/i \ \ \ \ template0 = 'red', " ~/.config/conky/conky.conf


#~ CONKY DISPLAY

#~ header

echo 'conky.text = [[
${color1}${alignc 40}${font FontAwesome6Free:bold:size=38}${voffset -5}${font Symbols Nerd Font Mono:normal:size=68}${font}${color1}${font FontAwesome6Free:bold:size=38}${voffset -20}${font Symbola:size=28}🄰🅁🄲🄷${font}${voffset -20}${color1}${font Symbola:size=28}🅻🅸🅽🆄🆇${font}

${color1}${font1}${font}${offset 6}:${color2}${scroll 33 Conky $conky_version - $sysname $nodename $kernel $machine}
${voffset 6}${color1}${font Symbols Nerd Font Mono:normal:size=20}${font}${offset 8}${voffset -4}${color2}$uptime${color1}${font Symbols Nerd Font Mono:normal:size=20}${alignr}${voffset -4}${font}${offset 10}${color2}${execi 3600 conky_tag_upgraded}${offset -10}
# ${voffset 6}${color1}${font FontAwesome6Free:bold:size=20}${font}${offset 8}${voffset -4}${color2}$uptime${color1}${font FontAwesome6Free:bold:size=16}${alignr}${voffset -4}${font}${offset 10}${color2}${execi 3600 conky_tag_upgraded}${offset -10}
${color1}$hr
${color1}${font1}${font}${offset 6}RAM Usage: ${color2}$mem/$memmax - $memperc% ${color1}${membar 4}
${color1}${font1}${font}${offset 6}Swap Usage: $swap/$swapmax - $swapperc% ${color1}${swapbar 4}
${color1}${font1}${font}${offset 6}CPU Usage: ${color2}$cpu% ${color1}${cpubar 4}
${color1}${font1}${font}${offset 6}Freq: ${color2}$freq_g GHz ${color1}Processes: ${color2}$processes ${color1}Running: ${color2}$running_processes
${color1}$hr
${color1}${font1}${font}${offset 6}File systems:
${font1}${font} / ${color2}${fs_used /}/${fs_size /} ${color1}${fs_bar 4 /}
${color1}$hr' >> ~/.config/conky/conky.conf


#~ set font and display symbol


#~ show only networks connected

network_list=$(nmcli dev status | awk '/^[^A-Z]/{print $1}')
for network in $network_list
do
    printf "\${if_existing /sys/class/net/$network/operstate up}\${color1}\${font1}\${font} \${color}$network \${alignr}\${color1}ip \${color2}\${addr $network} \${color1}id \${color2}\${wireless_essid $network}
\${color1}\$hr
\${color1}\${offset 180}\${font1}\${font}\${offset 6}Upload\${alignr 6}Download\${font1}\${offset 6}\${font}
\${color1}Current \${offset 91}\${color1} \${font1}\${font}\${offset 6}\${color2}\${upspeed $network}\${alignr 7}\${downspeed $network}\${color1}\${offset 6}\${font1}\${font}
\${color1}Total \${offset 121}\${color1}\${font1}\${font}\${offset 6}\${color2}\${totalup $network}\${alignr 7}\${totaldown $network}\${color1}\${offset 6}\${font1}\${font}
${color3}\$hr\${endif}" \
	 >> ~/.config/conky/conky.conf
done

#~ System usage

echo '
${color1}Mem buffered: ${color2}${buffers}${alignr}${color1}Cached: ${color2}${cached}
${color1}Name               PID     CPU%   MEM%
${color2} ${top name 1} ${top pid 1} ${top cpu 1} ${top mem 1}
${color2} ${top name 2} ${top pid 2} ${top cpu 2} ${top mem 2}
${color2} ${top name 3} ${top pid 3} ${top cpu 3} ${top mem 3}
${color2} ${top name 4} ${top pid 4} ${top cpu 4} ${top mem 4}
${voffset 20}
' \
>> ~/.config/conky/conky.conf



#~ add feature
'' >> ~/.config/conky/conky.conf


#~ end of conky.text
echo ']]
' >> ~/.config/conky/conky.conf


#~ show 
# cat ~/.config/conky/conky.conf
