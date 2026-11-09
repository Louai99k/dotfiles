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

### Theme (Rosé Pine for GTK + Qt)

1. Run `pacman -S gtk3 gtk4 qt5ct qt6ct qt5-wayland qt6-wayland breeze breeze-icons breeze-cursors kconfig ttf-jetbrains-mono-nerd xdg-desktop-portal-gtk xdg-desktop-portal-hyprland`

2. Stow puts the pieces in place:
    - GTK3 theme: `.local/share/themes/rose-pine-gtk`, vendored from [rose-pine/gtk](https://github.com/rose-pine/gtk) (see its `SOURCE` file)
    - GTK4: `.config/gtk-4.0/gtk.css`
    - Qt6: `.config/qt6ct`; Qt5: `.config/qt5ct` (reuses the qt6ct colors)
    - KDE apps (Dolphin): `.local/share/color-schemes/RosePine.colors`
    - sqlitebrowser (the only Qt5 app): `.local/share/applications/sqlitebrowser.desktop` runs it with `QT_QPA_PLATFORMTHEME=qt5ct`

3. `scripts/general/theme.sh` runs at every Hyprland start (through `bootstrap.sh`). It writes the GTK gsettings and merges the KDE scheme into `~/.config/kdeglobals`, neither of which can be stowed. Change theme values there, not in a GUI.

4. Don't use nwg-look; it overwrites these files.
