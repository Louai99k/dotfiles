#!/bin/bash
# --------------------------------------------------
#                ___  __    ___  _      ___  __  __  
#   /\  /\/\_/\ / _ \/__\  / _ \/_\    / _ \/__\/__\ 
#  / /_/ /\_ _// /_)/ \// / /_)//_\\  / /_)/_\ / \// 
# / __  /  / \/ ___/ _  \/ ___/  _  \/ ___//__/ _  \ 
# \/ /_/   \_/\/   \/ \_/\/   \_/ \_/\/   \__/\/ \_/ 
# --------------------------------------------------

# ~/.config/theme/wallpaper is linked by theme.sh from palette.conf. It
# runs at the same time on login, so create the link first if it's missing.
[[ -e ~/.config/theme/wallpaper ]] || ~/dotfiles/scripts/general/theme.sh

hyprpaper
