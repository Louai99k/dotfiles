# My Dot Files


## Installing

1. Create `.config`, `.icons` and `.local` folders at `/home/user`

2. Run `pacman -S git neovim wl-clipboard fzf zioxide zsh gcc gitui stow tmux make unzip ripgrep`

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
