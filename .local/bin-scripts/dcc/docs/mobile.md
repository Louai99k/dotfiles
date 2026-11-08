# dcc mobile

Opens the tmux workspace for mobile development and attaches to it. Script: mobile-tmux.sh.

    dcc mobile

If session client already exists, nothing is created and it just attaches. Otherwise it creates two sessions, then attaches to client on the mobile window:

    client
      1 mobile   ~/me/childcare/mobile, runs nvim .
      2 term     ~/me/childcare/mobile
      3 git      ~/me/childcare/mobile, runs gitui
      4 misc     ~/me/childcare
    backend
      1 backend  ~/me/childcare/backend, runs nvm use 20
      2 term     ~/me/childcare/backend, runs nvm use 20
      3 misc     ~/me/childcare/backend, runs gitui

Window numbers rely on set -g base-index 1 in .tmux.conf. Run it outside tmux, because tmux refuses a nested attach. Only client is checked, so if backend already exists without client, creating it prints an error and its windows are changed anyway. Extra arguments are ignored.

Options:

    -h, --help  Show this help without creating or attaching to anything.
