#!/usr/bin/env bash
# Runs a caveman hook only when caveman is installed on this machine.
# Missing caveman, node or the caveman npm package: exit 0 silently, so
# machines without caveman see no hook errors.
# Usage: caveman.sh native-hook | shrink-hook | blocks

# nvm's default node, resolved from ~/.nvm/alias without loading nvm.sh
# (follows alias chains like default -> lts/* -> lts/jod -> v22).
nvm_default_node() {
  local dir=${NVM_DIR:-$HOME/.nvm} v hops=0 match
  [ -r "$dir/alias/default" ] || return 1
  v=$(<"$dir/alias/default")
  while [ -r "$dir/alias/$v" ] && [ $hops -lt 5 ]; do v=$(<"$dir/alias/$v"); hops=$((hops + 1)); done
  v=${v#v}
  case $v in node | stable) v="*" ;; esac
  match=$(ls -d "$dir/versions/node/v"$v "$dir/versions/node/v"$v.* 2>/dev/null | sort -V | tail -n 1)
  [ -n "$match" ] && [ -x "$match/bin/node" ] && echo "$match/bin/node"
}

case "$1" in
  native-hook|shrink-hook)
    # Node: nvm's default version, else the system node. Caveman must be
    # installed for that node, otherwise skip.
    node=$(nvm_default_node) || node=$(PATH=/usr/local/bin:/usr/bin:/bin command -v node) || exit 0
    pkg="$(dirname "$node")/../lib/node_modules/@caveman-ai/cli"
    [ -d "$pkg" ] || exit 0
    if [ "$1" = native-hook ]; then
      proxy="$HOME/.caveman/bin/caveman-proxy"
      [ -x "$proxy" ] || exit 0
      exec "$proxy" native-hook claude --adapter "$pkg/dist/native-hook-fast.js" --node "$node"
    fi
    cli="$(dirname "$node")/caveman"
    [ -e "$cli" ] || exit 0
    exec "$node" "$cli" shrink-hook
    ;;
  blocks)
    blocks="$HOME/.local/share/caveman-blocks/bin/caveman-blocks"
    [ -x "$blocks" ] || exit 0
    exec "$blocks" hook --harness claude
    ;;
  *)
    exit 0
    ;;
esac
