#!/usr/bin/env bash
# --------------------------------------------------
# Refreshes the shared copies of Matt Pocock's skills (github.com/mattpocock/skills)
# in .agents/skills/ for Claude Code and Codex.
#
#   scripts/general/update-matt-skills.sh            # newest commit
#   scripts/general/update-matt-skills.sh <ref>      # a specific commit/tag/branch
#
# Replaces the skills listed below and prints the changed paths for review.
# The commit used is written to COMMIT below.
# --------------------------------------------------
set -euo pipefail

COMMIT="6f7f7831a625f040a8e06a0e7954826b87ce775a"

SKILLS=(
  ask-matt code-review codebase-design diagnosing-bugs domain-modeling
  grill-me grill-with-docs grilling handoff implement implement-spec
  improve-codebase-architecture prototype research retro setup-matt-pocock-skills
  tdd teach to-questionnaire to-spec to-tickets triage wait-what wayfinder wizard
  writing-for-agents
)

REF="${1:-}"
DOTFILES="$(cd "$(dirname "$0")/../.." && pwd)"
DEST="$DOTFILES/.agents/skills"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git clone -q https://github.com/mattpocock/skills.git "$tmp/src"
[[ -n "$REF" ]] && git -C "$tmp/src" checkout -q "$REF"
new_commit="$(git -C "$tmp/src" rev-parse HEAD)"

mkdir -p "$DEST"
for s in "${SKILLS[@]}"; do
  src="$(find "$tmp/src/skills" -mindepth 2 -maxdepth 2 -type d -name "$s" | head -1)"
  [[ -n "$src" ]] || { echo "skill not found upstream: $s" >&2; exit 1; }
  rm -rf "${DEST:?}/$s"
  cp -r "$src" "$DEST/$s"
done

sed -i "s/^COMMIT=\".*\"$/COMMIT=\"$new_commit\"/" "$0"
echo "Vendored ${#SKILLS[@]} skills at $new_commit"
git -C "$DOTFILES" status --short -- .agents/skills "$0"
