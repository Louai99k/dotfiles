---
name: configure-claude-walkthrough
description: "Contract for the 11-item \"Configure Claude\" walkthrough (CLAUDE.md, settings, permissions, hooks, ...) tracked in dotfiles"
metadata:
  node_type: memory
  type: project
  originSessionId: c5e1b842-bd59-4bc5-a218-cf7dd931e44a
  modified: 2026-11-18T10:32:51.419Z
---

Walkthrough of 11 Claude Code items, strictly one at a time: 1 Instructions (CLAUDE.md), 2 Settings, 3 Permissions, 4 Hooks, 5 Skills, 6 Subagents, 7 MCP servers, 8 Plugins, 9 Keybindings, 10 Status line, 11 Memory. Started 2026-11-15.

Per-item contract (revised by user 2026-11-18):
1. Explain: what it is, how it works, where files live.
2. Research + questions: search the web heavily for how users configure this item, then ask the user concrete questions to answer. Do NOT propose content from my own head; the user answers, and does not want to invent things themself.
3. User adds any extra instructions after answering.
4. Build (after approval), put in dotfiles, then move on.

**Why:** user wants config grounded in what others actually do, driven by their answers, not by my suggestions.
**How to apply:** after explaining an item, research first, then present questions (AskUserQuestion fits). Build only after answers + approval. Files go in `dotfiles/.claude/`, linked with stow; keep secrets/state out of git; commit to master per [[commit-directly-to-master]], no AI attribution.

Carry-overs agreed during items 1-3 (2026-11-18):
- Item #4 (Hooks): add a regex-based PreToolUse Bash hook that blocks `git push` in any form (`git -C dir push`, `git -c k=v push`) and sed's `w`/`e` commands, since permission rules only support `*` wildcards.
- Item #8 (Plugins): caveman hooks now go through a wrapper script (item #4); re-ask the user whether to migrate them to the plugin instead.

User's "recheck on my own later" list (after the base 11-item config is finished, remind the user of these):
- Hooks (#4): user loves hooks and will explore more hook ideas personally after the base config. Base pass only does the agreed essentials.
- Subagents (#6): user finds them fascinating and will explore custom subagents personally after the base config.
- mattpocock/skills (incl. Grill Me): user wants a dedicated standalone session about these later; not part of the base config.
- Item #8 (Plugins): user picked frontend-design, Context7, security-guidance from item #5 skill research (browser testing skipped for now); install them as plugins there.

Progress (2026-11-18): items 1-8 done and committed. #6 built web-researcher agents (Claude + Codex). #7 no changes (no new MCP servers). #8: caveman marketplace autoUpdate; item #5 plugin picks dropped (security-guidance is Python + pip venv); caveman hooks stay on the wrapper because the plugin only ships activate/mode-tracker hooks. #9 Keybindings: skipped by user choice, knowing it exists is enough.
#10 Status line: no config change; known issue (untracked caveman-statusline.sh) noted in .claude/GUIDE.md. #11 Memory: auto memory on; only this repo's memory folder is tracked (stowed folder link); Codex memories off. All 11 items done; carry-over lists above are resolved. .claude/GUIDE.md is the user's "need X, use Y" reference for everything deferred; add to it when Claude config changes.
