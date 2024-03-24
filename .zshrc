# --------------------------------------------------
# .zshrc to configure zsh
# --------------------------------------------------

# If not running interactively, don't do anything
if [[ ! -o interactive ]]; then
    return
fi

# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/zsh_completion" ] && \. "$NVM_DIR/zsh_completion"  # This loads nvm zsh_completion