#!/bin/env bash

# Set the session name
SESSION="childcare"
SSH_SESSION="ssh"
MISC_SESSION="misc"

tmux has-session -t $SESSION 2>/dev/null

if [ $? != 0 ]; then
  # Start a new tmux session with the specified session name
  tmux new-session -d -s $SESSION
  tmux new-session -d -s $SSH_SESSION
  tmux new-session -d -s $MISC_SESSION

  # Create the first window named 'backend' and navigate to the specified path
  tmux rename-window -t $SESSION:1 'backend'
  tmux send-keys -t $SESSION:1 'cd ~/me/childcare/backend' C-m
  tmux send-keys -t $SESSION:1 'nvim .' C-m

  # Create the second window named 'frontend' and navigate to the specified path
  tmux new-window -t $SESSION:2 -n 'frontend'
  tmux send-keys -t $SESSION:2 'cd ~/me/childcare/frontend' C-m
  tmux send-keys -t $SESSION:2 'nvim .' C-m

  # Create the third window named 'terms' and navigate to the specified path
  tmux new-window -t $SESSION:3 -n 'terms'
  tmux send-keys -t $SESSION:3 'cd ~/me/childcare/backend' C-m
  tmux send-keys -t $SESSION:3 'nvm use 18' C-m
  tmux split-window -t $SESSION:3
  tmux send-keys -t $SESSION:3 'cd ~/me/childcare/frontend' C-m
  tmux select-layout -t $SESSION:3 'main-horizontal'

  # Create the fourth window named 'general' and navigate to the specified path
  tmux new-window -t $SESSION:4 -n 'mobile'
  tmux send-keys -t $SESSION:4 'cd ~/me/childcare/mobile' C-m
  tmux send-keys -t $SESSION:4 'nvim .' C-m

  # Create the fifth window named 'git backend' and navigate to specified path and open gitui
  tmux new-window -t $SESSION:5 -n 'git-backend'
  tmux send-keys -t $SESSION:5 'cd ~/me/childcare/backend' C-m
  tmux send-keys -t $SESSION:5 'gitui' C-m

  # Create the fifth window named 'git frontend' and navigate to specified path and open gitui
  tmux new-window -t $SESSION:6 -n 'git-frontend'
  tmux send-keys -t $SESSION:6 'cd ~/me/childcare/frontend' C-m
  tmux send-keys -t $SESSION:6 'gitui' C-m

  tmux rename-window -t $SSH_SESSION:1 'staging'
  tmux send-keys -t $SSH_SESSION:1 'cd ~/me/childcare' C-m

  tmux new-window -t $SSH_SESSION:2 -n 'production'
  tmux send-keys -t $SSH_SESSION:2 'cd ~/me/childcare' C-m
fi

tmux attach-session -t $SESSION
