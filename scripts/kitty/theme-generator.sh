#!/bin/bash
# --------------------------------------------------
#  _____ _                             ___                          _             
# /__   \ |__   ___ _ __ ___   ___    / _ \___ _ __   ___ _ __ __ _| |_ ___  _ __ 
#   / /\/ '_ \ / _ \ '_ ` _ \ / _ \  / /_\/ _ \ '_ \ / _ \ '__/ _` | __/ _ \| '__|
#  / /  | | | |  __/ | | | | |  __/ / /_\\  __/ | | |  __/ | | (_| | || (_) | |   
#  \/   |_| |_|\___|_| |_| |_|\___| \____/\___|_| |_|\___|_|  \__,_|\__\___/|_|   
# --------------------------------------------------

COLOR_FILE_PATH=~/.cache/me/colors/colors.txt
LIGHT_COLOR_FILE_PATH=~/.cache/me/colors/light-colors.txt
THEME_FILE_PATH=~/dotfiles/.config/kitty/themes/theme.conf

if [ ! -e $THEME_FILE_PATH ]; then
  mkdir -p ~/dotfiles/.config/kitty/themes
fi

if [ -e $COLOR_FILE_PATH ]; then
  # Read colors into an array
  mapfile -t colors < $COLOR_FILE_PATH
  mapfile -t light_colors < $LIGHT_COLOR_FILE_PATH

  # Assign colors to variables
  color1=${colors[0]}
  color2=${colors[1]}
  color3=${colors[2]}
  color4=${colors[3]}
  color5=${colors[4]}
  light1=${light_colors[0]}
  light2=${light_colors[1]}
  light3=${light_colors[2]}
  cat << EOL > $THEME_FILE_PATH
foreground              #$light1
background              #1E1E2E
selection_foreground    #1E1E2E
selection_background    #$color2
background_opacity 1.0
cursor                  #$color2
cursor_text_color       #1E1E2E
url_color               #$color3
active_border_color     #$color1
inactive_border_color   #5d5d5d
bell_border_color       #$color4
wayland_titlebar_color  #1E1E2E
macos_titlebar_color    #1E1E2E
active_tab_foreground   #1E1E2E
active_tab_background   #$light2
inactive_tab_foreground #$light3
inactive_tab_background #1E1E2E
tab_bar_background      #111111
mark1_foreground #1E1E2E
mark1_background #$color1
mark2_foreground #1E1E2E
mark2_background #$light2
mark3_foreground #1E1E2E
mark3_background #$color5
color0 #45475A
color8 #585B70
color1 #F38BA8
color9 #F38BA8
color2  #A6E3A1
color10 #A6E3A1
color3  #F9E2AF
color11 #F9E2AF
color4  #89B4FA
color12 #89B4FA
color5  #F5C2E7
color13 #F5C2E7
color6  #94E2D5
color14 #94E2D5
color7  #BAC2DE
color15 #A6ADC8
EOL
else
  echo "" > $THEME_FILE_PATH
fi
