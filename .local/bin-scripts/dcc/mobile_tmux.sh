#!/bin/env bash

SESSION="client"
MISC_SESSION="backend"

tmux has-session -t $SESSION 2>/dev/null

if [ $? != 0 ]; then
  tmux new-session -d -s $SESSION
  tmux new-session -d -s $MISC_SESSION

  tmux rename-window -t $SESSION:1 'mobile'
  tmux send-keys -t $SESSION:1 'cd ~/me/childcare/mobile' C-m
  tmux send-keys -t $SESSION:1 'nvim .' C-m

  tmux new-window -t $SESSION:2 -n 'term'
  tmux send-keys -t $SESSION:2 'cd ~/me/childcare/mobile' C-m

  tmux new-window -t $SESSION:3 -n 'git'
  tmux send-keys -t $SESSION:3 'cd ~/me/childcare/mobile' C-m
  tmux send-keys -t $SESSION:3 'gitui' C-m

  tmux new-window -t $SESSION:4 -n 'misc'
  tmux send-keys -t $SESSION:4 'cd ~/me/childcare' C-m

  tmux select-window -t $SESSION:"mobile"

  tmux rename-window -t $MISC_SESSION:1 'backend'
  tmux send-keys -t $MISC_SESSION:1 'cd ~/me/childcare/backend' C-m
  tmux send-keys -t $MISC_SESSION:1 'nvm use 18' C-m

  tmux new-window -t $MISC_SESSION:2 -n 'term'
  tmux send-keys -t $MISC_SESSION:2 'cd ~/me/childcare/backend' C-m
  tmux send-keys -t $MISC_SESSION:2 'nvm use 18' C-m

  tmux new-window -t $MISC_SESSION:3 -n 'misc'
  tmux send-keys -t $MISC_SESSION:3 'cd ~/me/childcare/backend' C-m
  tmux send-keys -t $MISC_SESSION:3 'gitui' C-m
fi

tmux attach-session -t $SESSION
