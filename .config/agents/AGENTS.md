# Global agent instructions

Shared by Claude Code (imported from `~/.claude/CLAUDE.md`) and Codex (`~/.codex/AGENTS.md` links here). Only rules that apply to every project belong here; project rules live in each repo.

## Precedence

- If a repo or project instruction conflicts with this file, the project instruction wins.

## Environment

- Arch Linux. Packages: `pacman`, AUR via `paru`.
- Shell: `zsh` with Oh My Zsh.
- Desktop: Hyprland (Lua config) on Wayland, `waybar`, `wofi`, terminal `kitty`.
- Tools: `nvim`, `tmux`, `yazi`, `rg`, `fd`, `fzf`, `zoxide`, `gitui`, `stow`, `docker`.

## Scope

- Do only what the request needs. No drive-by fixes, refactors or cleanups.
- Mention other problems you notice; do not fix them unless asked.

## Ambiguity

- When a request has more than one reasonable reading, list the readings and ask before acting. Do not pick one silently.

## Missing prerequisites

- When my request depends on setup that does not exist, stop the dependent work and tell me what is missing. Ask how to proceed before adding or changing that setup.
- A request for an outcome does not authorize inventing or implementing missing prerequisites. This covers data, fields, timestamps, schemas, infrastructure, configuration and workflows.
- Do not silently choose a substitute, fallback, backfill or new data-collection behavior. Continue only independent work that does not need the decision.

## Installing software

- Never install packages (`pacman`, `paru`, `npm -g`, `pip`, `cargo`, ...) or run `sudo` yourself.
- Stop and tell me what is needed, with the suggested install method and exact command, so I can run it or give different instructions.

## Verification

- Do not run tests, typecheck, lint, build, dev servers, Playwright, simulators, emulators, app launches or any other verification command unless I explicitly ask.
- After edits, only inspect the changed files or diff when useful.

## Git

- When I ask to organize or create commits, run `git add`, `git commit`, read-only Git inspection and index-only operations without asking per command or per commit. Preserve working-tree changes.
- Pushes, destructive operations and rewriting existing history need my explicit approval.
- Match the repo's existing commit message style.
- Never add AI attribution (`Co-Authored-By` lines, "Generated with ..." lines, or similar) to commits, pull requests, tags or code comments. All work is authored by me.

## Secrets

- Do not read secret files (`.env` files, credentials, tokens, API keys, private keys) as a first approach. When reading one is truly necessary, say why and ask me first.
- Never print or commit secrets. Before committing, check the staged changes for secrets.

## Communication

- No flattery or filler praise. Push back when I am wrong.
