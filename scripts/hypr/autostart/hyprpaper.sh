#!/bin/bash
# --------------------------------------------------
#                ___  __    ___  _      ___  __  __  
#   /\  /\/\_/\ / _ \/__\  / _ \/_\    / _ \/__\/__\ 
#  / /_/ /\_ _// /_)/ \// / /_)//_\\  / /_)/_\ / \// 
# / __  /  / \/ ___/ _  \/ ___/  _  \/ ___//__/ _  \ 
# \/ /_/   \_/\/   \/ \_/\/   \_/ \_/\/   \__/\/ \_/ 
# --------------------------------------------------

if [[ -e ~/wallpapers/active.png ]]; then
  echo "Image exists"
else
  mkdir -p ~/wallpapers
  cp ~/dotfiles/wallpapers/default.png ~/wallpapers/active.png
fi

if which "colorsnap" > /dev/null; then
  colorsnap -f ~/wallpapers/active.png > ~/.cache/me/colors/colors.txt
  colorsnap -f ~/wallpapers/active.png -d -0.25 > ~/.cache/me/colors/light-colors.txt
  ~/dotfiles/scripts/btop/theme-generator.sh
  ~/dotfiles/scripts/kitty/theme-generator.sh
fi

hyprpaper
