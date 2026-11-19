# Claude Code guide

A personal lookup for "I want Claude to do X: what do I use?". Built from the
2026-11 walkthrough of the Claude Code config in these dotfiles. Claude does
not load this file automatically, so it costs no context.

Docs root: https://code.claude.com/docs/en/ (add the page name, e.g. `hooks`,
`sub-agents`, `mcp`, `discover-plugins`, `keybindings`, `statusline`).

## Quick lookup

| I want...                                                  | Use                    | Section                    |
| ---------------------------------------------------------- | ---------------------- | -------------------------- |
| Claude to always follow a rule                             | Instructions           | [1](#1-instructions)       |
| A rule only for one repo                                   | Project `CLAUDE.md`    | [1](#1-instructions)       |
| Change model, effort, env vars, theme, updates             | Settings               | [2](#2-settings)           |
| Stop the permission prompt for a safe command              | Permission allow rule  | [3](#3-permissions)        |
| Force a prompt (or a block) for a command or file          | Permission ask / deny  | [3](#3-permissions)        |
| Something to happen automatically, every time, guaranteed  | Hook                   | [4](#4-hooks)              |
| Block or question a command a wildcard rule can't match    | PreToolUse hook        | [4](#4-hooks)              |
| A reusable workflow or instructions I call by name         | Skill                  | [5](#5-skills)             |
| A side job that shouldn't fill my context                  | Subagent               | [6](#6-subagents)          |
| Claude to talk to an outside system (GitHub, docs, DB)     | MCP server             | [7](#7-mcp-servers)        |
| A ready-made bundle of skills/agents/hooks/MCP             | Plugin                 | [8](#8-plugins)            |
| Different keyboard shortcuts in the terminal app           | Keybindings            | [9](#9-keybindings)        |
| Live info at the bottom of the terminal app                | Status line            | [10](#10-status-line)      |
| Claude to remember something between sessions in a repo    | Auto memory            | [11](#11-memory)           |

Rule of thumb: instructions and skills are advice Claude may weigh; hooks and
permission rules are enforced by the harness. If it must happen, use a hook.

## What is set up now

| File in dotfiles                      | Linked to                  | What it does                                       |
| ------------------------------------- | -------------------------- | -------------------------------------------------- |
| `.config/agents/AGENTS.md`            | `~/.config/agents/`        | Global rules shared by Claude and Codex            |
| `.claude/CLAUDE.md`                   | `~/.claude/CLAUDE.md`      | Imports AGENTS.md, plus Claude-only rules          |
| `.codex/AGENTS.md` (symlink)          | `~/.codex/AGENTS.md`       | Same AGENTS.md for Codex                           |
| `.claude/settings.json`               | `~/.claude/settings.json`  | Model, env, permissions, hooks, plugins            |
| `.claude/hooks/`                      | `~/.claude/hooks` (folder) | `guard-bash` (git push / sed guard), caveman wrapper |
| `.claude/agents/web-researcher.md`    | file link in real dir      | Web research subagent (Sonnet), only when named    |
| `.codex/agents/web-researcher.toml`   | file link in real dir      | Same for Codex (`gpt-6.1-terra`)                   |
| `.codex/skills/organize-commits/`     | file link in real dir      | Codex-only commit skill                            |
| `.claude/projects/-home-luay-dotfiles/memory/` | folder link       | Claude's auto memory for this repo only            |
| `.codex/hooks.json`                   | `~/.codex/hooks.json`      | Codex hooks: caveman wrapper + guard-bash (codex)  |
| `.codex/rules/`                       | `~/.codex/rules` (folder)  | Codex command rules (`base.rules`)                 |

Not tracked on purpose: `~/.claude.json` (state + account data),
`~/.claude/.credentials.json`, `history.jsonl`, `projects/`, `sessions/`,
`plugins/` cache, `~/.codex/config.toml` (has machine trust hashes).

Stow note: a target folder that does not exist yet becomes one folder link;
one that exists gets one link per file. To keep untracked local files next to
tracked ones (like `~/.claude/agents`), create the real folder first, then stow.

## 1. Instructions

- `~/.claude/CLAUDE.md`: every project. Project: `CLAUDE.md` or
  `.claude/CLAUDE.md` in the repo. Private per repo: `CLAUDE.local.md`.
- `@path` imports another file. Keep each file short (under ~200 lines).
- `~/.claude/rules/*.md` and `.claude/rules/*.md` split rules into files.
- Global rules belong in `.config/agents/AGENTS.md` (shared with Codex).
  Project instructions win over global ones.

## 2. Settings

- Precedence: managed > CLI flags > `.claude/settings.local.json` >
  `.claude/settings.json` (project) > `~/.claude/settings.json` (user).
  Lists (permissions, hooks) merge across files.
- Most changes apply live. `/config` changes some settings interactively.
- Optional tools must be optional: a missing tool should be skipped, not error
  (see the caveman wrapper in `.claude/hooks/caveman.sh`).

## 3. Permissions

- Mode now: Manual (`defaultMode: "default"`). Add allow rules over time.
- Order: deny, then ask, then allow. First match wins in that order.
- Syntax: `Bash(git status *)`, `Read(~/**)`, `Read(//abs/path/**)`,
  `mcp__server__tool`, `Agent(Explore)`. Only `*` wildcards, no regex.
- Per repo first; make a rule global only when I decide to.
- Anything a wildcard can't express (like `git -C dir push`) goes in a
  PreToolUse hook instead.

## 4. Hooks

Commands the harness runs on events. Set under `hooks` in settings.json.

- Events used here: SessionStart, UserPromptSubmit, PreToolUse, PostToolUse,
  PostToolUseFailure, PreCompact, SubagentStart, SubagentStop, Stop,
  SessionEnd. More exist (e.g. Notification): check the `hooks` doc page.
- Input: JSON on stdin (tool name, tool input, session id, cwd...).
- Exit 0: OK, stdout may carry JSON. Exit 2: block, stderr goes to Claude.
  Any other exit or a missing command: non-blocking error, so it fails open.
  Wrap with a launcher that turns errors into exit 2 when it must fail closed.
- PreToolUse JSON can return `permissionDecision`: `allow`, `ask` or `deny`.
- `matcher` picks tools (e.g. `Bash`, `Edit|Write`, `mcp__github__.*`).
- Scripts: Bash first, Node if Bash gets too complex, never Python.
  Node: nvm's default version, else system node (see `nvm_default_node`).
- Ideas to explore: notify on Stop, auto-format after Edit, block edits to
  certain paths, log commands, inject context at SessionStart.

## 5. Skills

- A folder with `SKILL.md` (frontmatter `name`, `description`, then
  instructions). Claude loads it when the description matches, or I call
  `/name`.
- Claude: `~/.claude/skills/<name>/` or `.claude/skills/<name>/` per repo.
  Codex: `~/.codex/skills/` or `~/.agents/skills/`. Kept separate per tool.
- Runs in the same conversation. `context: fork` makes it run as a subagent.
- Skill vs subagent: skill = me, same context, extra instructions.
  Subagent = a separate agent with its own context, returns a summary.
- Want to explore: mattpocock/skills (incl. "Grill Me") in its own session.
  `skill-creator` is available for writing new skills.

## 6. Subagents

- Claude: `~/.claude/agents/<name>.md` (frontmatter + system prompt).
  Codex: `~/.codex/agents/<name>.toml` (`name`, `description`,
  `developer_instructions`, optional `model`, `[features]`).
- Frontmatter: `name`, `description` (required); `tools`,
  `disallowedTools`, `model`, `effort`, `permissionMode`, `maxTurns`,
  `skills`, `mcpServers`, `hooks`, `memory`, `isolation: worktree`, `color`.
- Call: name it in the prompt, `@agent-<name>`, or `claude --agent <name>`.
- Built-ins: Explore, Plan, general-purpose, claude-code-guide,
  statusline-setup. Override one by creating a file with the same name.
- Value is context isolation, not the persona. Few agents with distinct
  descriptions route better than many. Each one costs extra tokens.
- Codex can't set `sandbox_mode` per agent; it inherits the parent's.
- Ideas: code-reviewer (read-only, Sonnet), command/log runner (cheap model,
  returns only failures), debugger. Collections to pick from, after reading
  each file: VoltAgent/awesome-claude-code-subagents,
  VoltAgent/awesome-codex-subagents.

## 7. MCP servers

- External programs that give Claude tools: `mcp__<server>__<tool>`.
- Add: `claude mcp add [--scope user|project|local] <name> -- <cmd>` or
  `--transport http <name> <url>`. Manage with `/mcp`.
- Scopes: user and local live in `~/.claude.json` (can't be tracked);
  project lives in the repo's `.mcp.json` (tracked per repo).
  `mcpServers` in settings.json is NOT read.
- To track a user-level server: install it as a plugin (enabledPlugins is in
  the tracked settings.json), or keep a script of `claude mcp add` lines.
- Each server adds tool definitions and credentials. Pick 3-5 for weekly work.
- Popular: Context7 (current library docs; queries go to Upstash), GitHub
  (issues, PRs, Actions logs; needs token or OAuth), Playwright (browser),
  Sentry, Linear/Jira. Skip Filesystem and Sequential Thinking (redundant).
- Codex: `[mcp_servers.<name>]` in `~/.codex/config.toml`.
- Installed now: `caveman` (Claude and Codex).

## 8. Plugins

- Bundles of skills, commands, agents, hooks, MCP and LSP servers.
- `/plugin` to browse, install, enable, update. Shell: `claude plugin ...`.
  `claude plugin details <name>` shows the context cost.
- Tracked: `enabledPlugins` and `extraKnownMarketplaces` in settings.json.
  On a new machine Claude Code fetches them after the session starts; run
  `/reload-plugins`.
- Auto-update: on for the official marketplace; caveman set to
  `autoUpdate: true`; other third-party marketplaces off by default.
- Plugin hooks and MCP servers run as me, unsandboxed. Read before install.
- Plugin subagents ignore `hooks`, `mcpServers`, `permissionMode`.
- Candidates from research (official marketplace):
  - `frontend-design`: one UI skill, no hooks.
  - `context7`: hosted docs MCP, no key.
  - `security-guidance`: Python hooks, pip-installs Agent SDK into
    `~/.claude/security/`, LLM review on Stop (extra tokens). Conflicts with
    my no-Python rule.
  - LSP plugins (e.g. `typescript-lsp`): real diagnostics, go-to-definition.
  - `claude-md-management`, `code-simplifier`, `hookify` (Python).
  - `/code-review` and `/simplify` are already built in.
- Caveman's own plugin hooks are only activate + mode tracker. Its other
  hooks come from the caveman CLI and run through `.claude/hooks/caveman.sh`.

## 9. Keybindings

Not configured; defaults in use. Terminal app only (desktop app ignores it).

- File: `~/.claude/keybindings.json` (`/keybindings` creates it). Live reload.
- Blocks of `{ "context": "Chat", "bindings": { "ctrl+e": "chat:externalEditor" } }`.
- `null` unbinds; chords like `ctrl+k ctrl+s`; `command:<name>` runs a slash
  command (e.g. `"meta+g": "command:compact"`).
- Not rebindable: Ctrl+C, Ctrl+D, Ctrl+M, Ctrl+[, Ctrl+I, Ctrl+H.
- Vim mode is a setting in `/config`, separate from this file.

## 10. Status line

Currently caveman's mode badge. Terminal app only.

- `statusLine: { "type": "command", "command": "..." }` in settings.json.
- The command gets session JSON on stdin (model, cwd, cost, context usage,
  session id...) and prints the line. Colors and multiple lines allowed.
- Local only, no tokens. Keep it fast.
- `/statusline` asks the built-in agent to write one.
- Known issue: `~/.claude/caveman-statusline.sh` is not tracked, so a machine
  without caveman shows nothing or an error. Fix like the hooks wrapper if it
  matters.

## 11. Memory

Claude's own notes, so a new session knows what earlier ones learned.
CLAUDE.md is what I write; memory is what Claude writes.

- Per repo: `~/.claude/projects/<repo-path>/memory/`, with a `MEMORY.md`
  index (first 200 lines / 25KB load every session) and one file per note.
  Note types: user, feedback, project, reference.
- Claude saves on its own, or when I say "remember X". `/memory` browses,
  edits and toggles it. Notes are plain markdown: edit or delete freely.
- Advice only, like CLAUDE.md. Must-happen behavior goes in a hook.
- Settings: `autoMemoryEnabled` (on by default), `autoMemoryDirectory`
  (one path; at user level probably shared by all projects),
  `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`.
- Machine-local by default. Only the dotfiles repo's memory is tracked here;
  new notes show up in `git status` for review. Other repos stay local
  (they can hold private project details).
- Subagents don't see it; a subagent gets its own via the `memory` field.
- Codex: memories off (default). `[features] memories = true` turns on
  background summaries of past chats into `~/.codex/memories/`, one store
  for all projects, uses rate limit. Don't hand-edit; use `/memories`.

## Codex equivalents

| Claude item   | Codex                                                                 |
| ------------- | --------------------------------------------------------------------- |
| Instructions  | `~/.codex/AGENTS.md` links to the same AGENTS.md                      |
| Settings      | `~/.codex/config.toml`, untracked: it also holds project trust and hook trust hashes, and Codex rewrites it. Set by hand: `[analytics] enabled = false` |
| Permissions   | Sandbox + approvals instead of allow/ask lists: `sandbox_mode` (`read-only`, `workspace-write`, `danger-full-access`), `approval_policy` (`on-request`, `never`). Command rules in `~/.codex/rules/*.rules`: `prefix_rule(pattern=[...], decision="allow"/"prompt"/"forbidden")`, token prefixes only, strictest match wins. Approving "always" in the TUI writes `default.rules` there. No file-read rules: secret files rely on AGENTS.md |
| Hooks         | `~/.codex/hooks.json`, same shape as Claude's. PreToolUse can only deny (exit 2 or deny JSON), not ask; errors fail open. New or changed hooks are skipped until trusted with `/hooks`. Hosted tools (web search) bypass hooks |
| Attribution   | No local switch (OpenAI account setting). guard-bash blocks commits with AI trailers |
| Skills        | `~/.codex/skills/`, `~/.agents/skills/`                               |
| Subagents     | `~/.codex/agents/*.toml`; can't set sandbox per agent                 |
| MCP           | `[mcp_servers.<name>]` in config.toml                                 |
| Plugins       | `codex plugin`, `[plugins."name@marketplace"]` in config.toml          |
| Memory        | Off. `[features] memories = true` to try                              |

## Per-machine setup reminders

- Caveman telemetry: run `caveman telemetry off` on each machine
  (`~/.caveman` is not tracked).
- Create `~/.claude/agents` and `~/.codex/agents` as real folders before
  `stow .`, so only the tracked agents get linked.
- Codex: add `[analytics] enabled = false` to `~/.codex/config.toml`, then
  run `/hooks` in Codex and trust the hooks from `hooks.json`.
- Re-running the caveman installer may rewrite `~/.codex/hooks.json`
  (through the link): check `git diff` afterwards.
