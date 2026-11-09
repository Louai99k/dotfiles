# My Dot Files


## Installing

1. Create `.config`, `.icons`, `.local/share` and `.local/share/applications` folders at `/home/user`. Stow links a whole folder when it doesn't exist yet, and apps must not write their data into this repo

2. Run `pacman -S git neovim wl-clipboard fzf zioxide zsh gcc gitui stow tmux make unzip ripgrep docker docker-compose docker-buildx yazi openssh`

3. Run:

```bash
tee .stow-global-ignore > /dev/null << EOF
\.git
\.gitignore
^/README.*
^/LICENCE.*
wallpapers
scripts
EOF
```
4. Clone this Repo with `--recursive` flag fro neovim submodule

5. Install Oh My ZSH from [here](https://ohmyz.sh/#install) and **DON'T REPLACE `.zshrc` file**

### Node

1. Install [nvm](https://github.com/nvm-sh/nvm). Installing `nvm` will add a line to `.zshrc` so remove it

### Rust

1. Install `rustup` via [link](https://rustup.rs/)

### Neovim

1. Open neovim once to get all plugins installed

2. Run `MasonInstall lua-language-server` and all other required lsp servers

### TMUX

1. Install `tmux` `tpm` with `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`

2. Open `tmux` and `Ctrl+B` then `I`


### Docker

1. Run `sudo usermod -aG docker $USER` for non-sudo usage
2. Run `sudo systemctl enable --now docker.service` for enabling docker

### Theme (colors + wallpaper)

1. Run `pacman -S gtk3 gtk4 qt5ct qt6ct qt5-wayland qt6-wayland breeze breeze-icons breeze-cursors kconfig glib2 ttf-jetbrains-mono-nerd xdg-desktop-portal-gtk xdg-desktop-portal-hyprland`

2. **Single source of truth:** `.config/theme/palette.conf` holds every color (Rosé Pine by default), the accent and the wallpaper. After editing it run `scripts/general/theme.sh --reload`. The same script runs at every Hyprland start through `bootstrap.sh`.

3. What reads the palette:
    - waybar, wofi, wlogout, GTK4 (`.config/gtk-4.0/gtk.css`): `@import` the generated `.config/theme/colors.css` and use `@base`, `@accent`, ...
    - hyprlock: `source`s the generated `.config/theme/colors.hypr` and uses `$base`, `$accent`, ...
    - kitty, btop, mako, qt6ct/qt5ct, KDE apps (Dolphin), wlogout icons, clipse: whole files rendered from `.config/theme/templates/<path>` into `<path>`. Use `{{name}}` for hex without `#` and `{{name_rgb}}` for `r,g,b`
    - GTK3: the upstream [rose-pine/gtk](https://github.com/rose-pine/gtk) theme in `.config/theme/gtk3` is recolored and compiled into `.local/share/themes/dotfiles`. Only exact palette colors are swapped, so shades upstream derived from them keep their Rosé Pine values
    - hyprpaper: `.config/theme/wallpaper`, a link to the wallpaper picked in the palette
    - gsettings and `~/.config/kdeglobals` can't be stowed; `theme.sh` writes them

4. Generated files are gitignored. When adding a template, add its output to `.gitignore`; `theme.sh` warns if you forget. Edit templates, never the generated files.

5. sqlitebrowser (the only Qt5 app): `.local/share/applications/sqlitebrowser.desktop` runs it with `QT_QPA_PLATFORMTHEME=qt5ct`.

6. Don't use nwg-look; it overwrites these files.
