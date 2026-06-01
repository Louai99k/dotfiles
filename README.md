# My Dot Files


## Installing

1. Create `.config`, `.icons` and `.local` folders at `/home/user`

2. Run `pacman -S git neovim wl-clipboard fzf zioxide zsh gcc gitui stow`

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

5. After that install Oh My ZSH from [here](https://ohmyz.sh/#install) and **DON'T REPLACE `.zshrc` file**
