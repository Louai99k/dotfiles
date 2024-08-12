# --------------------------------------------------
#           _              
#   _______| |__  _ __ ___ 
#  |_  / __| '_ \| '__/ __|
#   / /\__ \ | | | | | (__ 
#  /___|___/_| |_|_|  \___|
#                          
# --------------------------------------------------

# If not running interactively, don't do anything
if [[ ! -o interactive ]]; then
    return
fi

# Aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias 'tmux a'='tmux attach'
alias 'vol'='pactl set-sink-volume @DEFAULT_SINK@'

# Prompt
PROMPT="%d > "

# ZSH history
HISTFILE=~/.zsh_histroy
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY

# Android Studio's Env Vars
export ANDROID_HOME=~/Android/Sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools

# node version manager (nvm)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/zsh_completion" ] && \. "$NVM_DIR/zsh_completion"  # This loads nvm zsh_completion

# executing cli utils
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
