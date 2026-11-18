---
name: hyprland-lua-migration
description: Hyprland config migrated to split Lua files on 2026-11-08 for 0.57; old hyprlang config now only in git history at d9bbd2d
metadata:
  node_type: memory
  type: project
  originSessionId: e266d5dc-6d28-4c3e-bbc3-f6bb26903a81
  modified: 2026-11-08T09:15:39.657Z
---

On 2026-11-08 the user's Hyprland config moved from hyprlang to Lua in `~/dotfiles/.config/hypr/`, because Hyprland 0.57 dropped `.conf` support. The port was faithful to the old config: no sample defaults were added. The user wants the config split like the old one: `hyprland.lua` only `require`s `autostart`, `env`, `binds`, `variables`, `monitor`, `window` (`.lua` files beside it).

The user had the backup folder removed because git keeps the old config. Read it with `git show d9bbd2d:.config/hypr/<name>.conf` (hyprland, autostart, binds, env, monitor, variables, window).

`hyprlock.conf` and `hyprpaper.conf` were deliberately left in place: those tools still read hyprlang.

**Why:** Legacy files record the user's original intent, and the Lua API differs enough that behavior questions may need comparing the two.

**How to apply:** Use `/usr/share/hypr/stubs/hl.meta.lua` as the exact API reference, since wiki pages can truncate when fetched. Validate before touching the live config, because the user cares that changes apply to the running system immediately: copy the entry file and modules to one scratch directory and run `Hyprland --verify-config -c <copy>/hyprland.lua` (`require` resolves from that file's directory). Write new modules first and change `hyprland.lua` last.
