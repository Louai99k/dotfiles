#!/usr/bin/env bash
# --------------------------------------------------
# Vendors a chosen subset of Matt Pocock's skills (github.com/mattpocock/skills)
# into .claude/skills/, as user-level Claude Code skills.
#
#   scripts/general/update-matt-skills.sh            # newest commit
#   scripts/general/update-matt-skills.sh <ref>      # a specific commit/tag/branch
#
# Replaces only the skills listed below, then prints the git diff so you can
# review the update before committing. The commit used is written to COMMIT below.
# --------------------------------------------------
set -euo pipefail

COMMIT="6f7f7831a625f040a8e06a0e7954826b87ce775a"

# Skills I use, plus the skills they call through the Skill tool.
SKILLS=(
  # used directly
  grill-with-docs wayfinder triage ask-matt to-spec to-tickets implement
  retro teach handoff prototype research code-review
  # dependencies
  grilling domain-modeling tdd codebase-design writing-for-agents
  setup-matt-pocock-skills
)

REF="${1:-}"
DOTFILES="$(cd "$(dirname "$0")/../.." && pwd)"
DEST="$DOTFILES/.claude/skills"

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
git -C "$DOTFILES" status --short -- .claude/skills "$0"
