# dcc web

Opens the tmux workspace for web development and attaches to it. Script: web-tmux.sh.

    dcc web

If session childcare already exists, nothing is created and it just attaches. Otherwise it creates three sessions, then attaches to childcare:

    childcare
      1 backend       ~/me/childcare/backend, runs nvim .
      2 frontend      ~/me/childcare/frontend, runs nvim .
      3 terms         Two panes: backend and frontend folders, main-horizontal layout
      4 mobile        ~/me/childcare/mobile, runs nvim .
      5 git-backend   ~/me/childcare/backend, runs gitui
      6 git-frontend  ~/me/childcare/frontend, runs gitui
    ssh
      1 staging       ~/me/childcare, no connection is opened
      2 production    ~/me/childcare, no connection is opened
    misc
      Empty session

Window numbers rely on set -g base-index 1 in .tmux.conf. Run it outside tmux, because tmux refuses a nested attach. Only childcare is checked, so if ssh or misc already exists without childcare, creating it prints an error and its windows are changed anyway. Extra arguments are ignored.

Options:

    -h, --help  Show this help without creating or attaching to anything.
