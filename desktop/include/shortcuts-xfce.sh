#!/bin/bash
#
# ./shorcuts-xfce.sh
#  customize key shorcuts for xfce with terminal command: xfconfig-query 


### BASH SCRIPT FLAGS FOR SECURITY AND DEBUGGING ###################

# shopt -o noclobber # avoid file overwriting (>) but can be forced (>|)
set +o history     # disably bash history temporarilly
set -o errtrace    # inherit any trap on ERROR
set -o functrace   # inherit any trap on DEBUG and RETURN
set -o errexit     # EXIT if script command fails
set -o nounset     # EXIT if script try to use undeclared variables
set -o pipefail    # CATCH failed piped commands
set -o xtrace      # trace & expand what gets executed (useful for debug)



## delete previous undesired key shortcuts
xfconf-query -c xfce4-keyboard-shortcuts \
	     -p '/commands/custom/<Alt>F1' \
	     -r -R

xfconf-query -c xfce4-keyboard-shortcuts \
	     -p '/commands/default/<Alt>F1' \
	     -r -R

## set new key shortcut
xfconf-query -c xfce4-keyboard-shortcuts \
	     -n -t 'string' \
	     -p '/commands/custom/<Primary>' \
	     --set xfce4-popup-applicationsmenu


# /commands/custom/<Alt>F1                   xfce4-popup-applicationsmenu
# /commands/custom/<Alt>F2                   xfce4-appfinder --collapsed
# /commands/custom/<Alt>F2/startup-notify    true
# /commands/custom/<Alt>F3                   xfce4-appfinder
# /commands/custom/<Alt>F3/startup-notify    true
# /commands/custom/<Alt>Print                xfce4-screenshooter -w
# /commands/custom/<Primary><Alt>Delete      xfce4-session-logout
# /commands/custom/<Primary><Alt>Escape      xkill
# /commands/custom/<Primary><Alt>f           thunar
# /commands/custom/<Primary><Alt>l           xflock4
# /commands/custom/<Primary><Alt>t           exo-open --launch TerminalEmulator
# /commands/custom/<Primary><Shift>Escape    xfce4-taskmanager
# /commands/custom/<Primary>Escape           xfdesktop --menu
# /commands/custom/<Shift>Print              xfce4-screenshooter -r
# /commands/custom/<Super>e                  thunar
# /commands/custom/<Super>p                  xfce4-display-settings --minimal
# /commands/custom/<Super>r                  xfce4-appfinder -c
# /commands/custom/<Super>r/startup-notify   true
# /commands/custom/HomePage                  exo-open --launch WebBrowser
# /commands/custom/Print                     xfce4-screenshooter
# /commands/custom/XF86Display               xfce4-display-settings --minimal
# /commands/custom/XF86Mail                  exo-open --launch MailReader
# /commands/custom/XF86WWW                   exo-open --launch WebBrowser
# /commands/custom/override                  true
# /commands/default/<Alt>F1                  xfce4-popup-applicationsmenu
# /commands/default/<Alt>F2                  xfce4-appfinder --collapsed
# /commands/default/<Alt>F2/startup-notify   true
# /commands/default/<Alt>F3                  xfce4-appfinder
# /commands/default/<Alt>F3/startup-notify   true
# /commands/default/<Alt>Print               xfce4-screenshooter -w
# /commands/default/<Primary><Alt>Delete     xfce4-session-logout
# /commands/default/<Primary><Alt>Escape     xkill
# /commands/default/<Primary><Alt>f          thunar
# /commands/default/<Primary><Alt>l          xflock4
# /commands/default/<Primary><Alt>t          exo-open --launch TerminalEmulator
# /commands/default/<Primary><Shift>Escape   xfce4-taskmanager
# /commands/default/<Primary>Escape          xfdesktop --menu
# /commands/default/<Shift>Print             xfce4-screenshooter -r
# /commands/default/<Super>e                 thunar
# /commands/default/<Super>p                 xfce4-display-settings --minimal
# /commands/default/<Super>r                 xfce4-appfinder -c
# /commands/default/<Super>r/startup-notify  true
# /commands/default/HomePage                 exo-open --launch WebBrowser
# /commands/default/Print                    xfce4-screenshooter
# /commands/default/XF86Display              xfce4-display-settings --minimal
# /commands/default/XF86Mail                 exo-open --launch MailReader
# /commands/default/XF86WWW                  exo-open --launch WebBrowser
# /providers                                 <<UNSUPPORTED>>
# /xfwm4/custom/<Alt><Shift>Tab              cycle_reverse_windows_key
# /xfwm4/custom/<Alt>Delete                  del_workspace_key
# /xfwm4/custom/<Alt>F10                     maximize_window_key
# /xfwm4/custom/<Alt>F11                     fullscreen_key
# /xfwm4/custom/<Alt>F12                     above_key
# /xfwm4/custom/<Alt>F4                      close_window_key
# /xfwm4/custom/<Alt>F6                      stick_window_key
# /xfwm4/custom/<Alt>F7                      move_window_key
# /xfwm4/custom/<Alt>F8                      resize_window_key
# /xfwm4/custom/<Alt>F9                      hide_window_key
# /xfwm4/custom/<Alt>Insert                  add_workspace_key
# /xfwm4/custom/<Alt>Tab                     cycle_windows_key
# /xfwm4/custom/<Alt>space                   popup_menu_key
# /xfwm4/custom/<Primary><Alt>Down           down_workspace_key
# /xfwm4/custom/<Primary><Alt>End            move_window_next_workspace_key
# /xfwm4/custom/<Primary><Alt>Home           move_window_prev_workspace_key
# /xfwm4/custom/<Primary><Alt>KP_1           move_window_workspace_1_key
# /xfwm4/custom/<Primary><Alt>KP_2           move_window_workspace_2_key
# /xfwm4/custom/<Primary><Alt>KP_3           move_window_workspace_3_key
# /xfwm4/custom/<Primary><Alt>KP_4           move_window_workspace_4_key
# /xfwm4/custom/<Primary><Alt>KP_5           move_window_workspace_5_key
# /xfwm4/custom/<Primary><Alt>KP_6           move_window_workspace_6_key
# /xfwm4/custom/<Primary><Alt>KP_7           move_window_workspace_7_key
# /xfwm4/custom/<Primary><Alt>KP_8           move_window_workspace_8_key
# /xfwm4/custom/<Primary><Alt>KP_9           move_window_workspace_9_key
# /xfwm4/custom/<Primary><Alt>Left           left_workspace_key
# /xfwm4/custom/<Primary><Alt>Right          right_workspace_key
# /xfwm4/custom/<Primary><Alt>Up             up_workspace_key
# /xfwm4/custom/<Primary><Alt>d              show_desktop_key
# /xfwm4/custom/<Primary><Shift><Alt>Left    move_window_left_key
# /xfwm4/custom/<Primary><Shift><Alt>Right   move_window_right_key
# /xfwm4/custom/<Primary><Shift><Alt>Up      move_window_up_key
# /xfwm4/custom/<Primary>F1                  workspace_1_key
# /xfwm4/custom/<Primary>F10                 workspace_10_key
# /xfwm4/custom/<Primary>F11                 workspace_11_key
# /xfwm4/custom/<Primary>F12                 workspace_12_key
# /xfwm4/custom/<Primary>F2                  workspace_2_key
# /xfwm4/custom/<Primary>F3                  workspace_3_key
# /xfwm4/custom/<Primary>F4                  workspace_4_key
# /xfwm4/custom/<Primary>F5                  workspace_5_key
# /xfwm4/custom/<Primary>F6                  workspace_6_key
# /xfwm4/custom/<Primary>F7                  workspace_7_key
# /xfwm4/custom/<Primary>F8                  workspace_8_key
# /xfwm4/custom/<Primary>F9                  workspace_9_key
# /xfwm4/custom/<Shift><Alt>Page_Down        lower_window_key
# /xfwm4/custom/<Shift><Alt>Page_Up          raise_window_key
# /xfwm4/custom/<Super>KP_Down               tile_up_key
# /xfwm4/custom/<Super>KP_End                tile_down_left_key
# /xfwm4/custom/<Super>KP_Home               tile_up_left_key
# /xfwm4/custom/<Super>KP_Left               tile_left_key
# /xfwm4/custom/<Super>KP_Next               tile_down_right_key
# /xfwm4/custom/<Super>KP_Page_Up            tile_up_right_key
# /xfwm4/custom/<Super>KP_Right              tile_right_key
# /xfwm4/custom/<Super>KP_Up                 tile_down_key
# /xfwm4/custom/<Super>Tab                   switch_window_key
# /xfwm4/custom/Down                         down_key
# /xfwm4/custom/Escape                       cancel_key
# /xfwm4/custom/Left                         left_key
# /xfwm4/custom/Right                        right_key
# /xfwm4/custom/Up                           up_key
# /xfwm4/custom/override                     true
# /xfwm4/default/<Alt><Shift>Tab             cycle_reverse_windows_key
# /xfwm4/default/<Alt>Delete                 del_workspace_key
# /xfwm4/default/<Alt>F10                    maximize_window_key
# /xfwm4/default/<Alt>F11                    fullscreen_key
# /xfwm4/default/<Alt>F12                    above_key
# /xfwm4/default/<Alt>F4                     close_window_key
# /xfwm4/default/<Alt>F6                     stick_window_key
# /xfwm4/default/<Alt>F7                     move_window_key
# /xfwm4/default/<Alt>F8                     resize_window_key
# /xfwm4/default/<Alt>F9                     hide_window_key
# /xfwm4/default/<Alt>Insert                 add_workspace_key
# /xfwm4/default/<Alt>Tab                    cycle_windows_key
# /xfwm4/default/<Alt>space                  popup_menu_key
# /xfwm4/default/<Primary><Alt>Down          down_workspace_key
# /xfwm4/default/<Primary><Alt>End           move_window_next_workspace_key
# /xfwm4/default/<Primary><Alt>Home          move_window_prev_workspace_key
# /xfwm4/default/<Primary><Alt>KP_1          move_window_workspace_1_key
# /xfwm4/default/<Primary><Alt>KP_2          move_window_workspace_2_key
# /xfwm4/default/<Primary><Alt>KP_3          move_window_workspace_3_key
# /xfwm4/default/<Primary><Alt>KP_4          move_window_workspace_4_key
# /xfwm4/default/<Primary><Alt>KP_5          move_window_workspace_5_key
# /xfwm4/default/<Primary><Alt>KP_6          move_window_workspace_6_key
# /xfwm4/default/<Primary><Alt>KP_7          move_window_workspace_7_key
# /xfwm4/default/<Primary><Alt>KP_8          move_window_workspace_8_key
# /xfwm4/default/<Primary><Alt>KP_9          move_window_workspace_9_key
# /xfwm4/default/<Primary><Alt>Left          left_workspace_key
# /xfwm4/default/<Primary><Alt>Right         right_workspace_key
# /xfwm4/default/<Primary><Alt>Up            up_workspace_key
# /xfwm4/default/<Primary><Alt>d             show_desktop_key
# /xfwm4/default/<Primary><Shift><Alt>Left   move_window_left_key
# /xfwm4/default/<Primary><Shift><Alt>Right  move_window_right_key
# /xfwm4/default/<Primary><Shift><Alt>Up     move_window_up_key
# /xfwm4/default/<Primary>F1                 workspace_1_key
# /xfwm4/default/<Primary>F10                workspace_10_key
# /xfwm4/default/<Primary>F11                workspace_11_key
# /xfwm4/default/<Primary>F12                workspace_12_key
# /xfwm4/default/<Primary>F2                 workspace_2_key
# /xfwm4/default/<Primary>F3                 workspace_3_key
# /xfwm4/default/<Primary>F4                 workspace_4_key
# /xfwm4/default/<Primary>F5                 workspace_5_key
# /xfwm4/default/<Primary>F6                 workspace_6_key
# /xfwm4/default/<Primary>F7                 workspace_7_key
# /xfwm4/default/<Primary>F8                 workspace_8_key
# /xfwm4/default/<Primary>F9                 workspace_9_key
# /xfwm4/default/<Shift><Alt>Page_Down       lower_window_key
# /xfwm4/default/<Shift><Alt>Page_Up         raise_window_key
# /xfwm4/default/<Super>KP_Down              tile_up_key
# /xfwm4/default/<Super>KP_End               tile_down_left_key
# /xfwm4/default/<Super>KP_Home              tile_up_left_key
# /xfwm4/default/<Super>KP_Left              tile_left_key
# /xfwm4/default/<Super>KP_Next              tile_down_right_key
# /xfwm4/default/<Super>KP_Page_Up           tile_up_right_key
# /xfwm4/default/<Super>KP_Right             tile_right_key
# /xfwm4/default/<Super>KP_Up                tile_down_key
# /xfwm4/default/<Super>Tab                  switch_window_key
# /xfwm4/default/Down                        down_key
# /xfwm4/default/Escape                      cancel_key
# /xfwm4/default/Left                        left_key
# /xfwm4/default/Right                       right_key
# /xfwm4/default/Up                          up_key
