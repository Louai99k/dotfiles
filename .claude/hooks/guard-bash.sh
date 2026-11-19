#!/usr/bin/env bash
# PreToolUse hook for Bash: runs guard-bash.mjs with node.
# Usage: guard-bash.sh [claude|codex] (default claude; with codex, asks become allows).
# Node: nvm's default version, else the system node. Node is required:
# no node, or any result other than exit 0, blocks (exit 2), because
# Claude Code only blocks on exit 2.

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

node=$(nvm_default_node) || node=$(PATH=/usr/local/bin:/usr/bin:/bin command -v node)
[ -x "$node" ] || { echo "guard-bash: node not found; blocking (node is required)" >&2; exit 2; }
"$node" "$(dirname "$(readlink -f "$0")")/guard-bash.mjs" "$@" || exit 2
