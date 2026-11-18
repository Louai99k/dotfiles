---
name: commit-directly-to-master
description: "In the dotfiles repo, commit directly on master instead of creating a branch"
metadata:
  node_type: memory
  type: feedback
  originSessionId: e266d5dc-6d28-4c3e-bbc3-f6bb26903a81
  modified: 2026-11-08T09:17:10.765Z
---

In `~/dotfiles`, commit directly on `master`. Don't create a branch first.

**Why:** The user said "No need for new branch just put them directly on master" after a Hyprland config commit landed on a feature branch. It's a personal repo where the branch only added a merge step.

**How to apply:** When the user asks for a commit in this repo, commit on `master`. Pushing still needs its own request. Related: [[hyprland-lua-migration]].
