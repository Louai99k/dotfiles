#!/bin/bash
# --------------------------------------------------
#  _____ _                             ___                          _             
# /__   \ |__   ___ _ __ ___   ___    / _ \___ _ __   ___ _ __ __ _| |_ ___  _ __ 
#   / /\/ '_ \ / _ \ '_ ` _ \ / _ \  / /_\/ _ \ '_ \ / _ \ '__/ _` | __/ _ \| '__|
#  / /  | | | |  __/ | | | | |  __/ / /_\\  __/ | | |  __/ | | (_| | || (_) | |   
#  \/   |_| |_|\___|_| |_| |_|\___| \____/\___|_| |_|\___|_|  \__,_|\__\___/|_|   
# --------------------------------------------------

COLOR_FILE_PATH=~/.cache/me/colors/colors.txt
THEME_FILE_PATH=~/dotfiles/.config/btop/themes/my-theme.theme

if [ ! -e $THEME_FILE_PATH ]; then
  mkdir -p ~/dotfiles/.config/btop/themes
fi

if [ -e $COLOR_FILE_PATH ]; then
  # Read colors into an array
  mapfile -t colors < $COLOR_FILE_PATH

  # Assign colors to variables
  color1=${colors[0]}
  color2=${colors[1]}
  color3=${colors[2]}
  color4=${colors[3]}
  color5=${colors[4]}
  color6=${colors[5]}
  cat << EOL > $THEME_FILE_PATH
theme[main_bg]="#111111"
theme[main_fg]="#$color2"
theme[title]="#$color1"
theme[hi_fg]="#$color3"
theme[selected_bg]="#$color1" 
theme[selected_fg]="#FF"
theme[inactive_fg]="#313131"
theme[proc_misc]="#$color2"
theme[cpu_box]="#$color5"
theme[mem_box]="#$color5"
theme[net_box]="#$color5"
theme[proc_box]="#$color5"
theme[div_line]="#$color5"
theme[temp_start]="#$color4"
theme[temp_mid]="#$color4"
theme[temp_end]="#$color6"
theme[cpu_start]="#$color4"
theme[cpu_mid]="#$color4"
theme[cpu_end]="#$color6"
theme[free_start]="#$color4"
theme[free_mid]="#$color4"
theme[free_end]="#$color6"
theme[cached_start]="#$color4"
theme[cached_mid]="#$color4"
theme[cached_end]="#$color6"
theme[available_start]="#$color4"
theme[available_mid]="#$color4"
theme[available_end]="#$color6"
theme[used_start]="#$color4"
theme[used_mid]="#$color4"
theme[used_end]="#$color6"
theme[download_start]="#$color4"
theme[download_mid]="#$color4"
theme[download_end]="#$color6"
theme[upload_start]="#$color4"
theme[upload_mid]="#$color4"
theme[upload_end]="#$color6"
EOL
else
  echo "" > $THEME_FILE_PATH
fi
