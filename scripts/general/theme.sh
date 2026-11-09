#!/bin/bash
# GTK reads these from dconf on Wayland, which isn't a file stow can track.
# Re-applied at every Hyprland start so git stays the source of truth.

gs() { gsettings set org.gnome.desktop.interface "$@"; }

gs gtk-theme 'rose-pine-gtk'
gs icon-theme 'breeze-dark'
gs cursor-theme 'breeze_cursors'
gs cursor-size 24
gs font-name 'JetBrainsMono Nerd Font 11'
gs document-font-name 'JetBrainsMono Nerd Font 11'
gs monospace-font-name 'JetBrainsMono Nerd Font Mono 11'
gs color-scheme 'prefer-dark'

# KDE apps (Dolphin, ...) take colors and icons from kdeglobals, which they
# also write to, so it isn't stowed. Merge the tracked scheme into it instead.
scheme="$HOME/.local/share/color-schemes/RosePine.colors"
if [[ -f "$scheme" ]]; then
	groups=()
	while IFS= read -r line; do
		[[ -z "$line" || "$line" == \#* ]] && continue
		if [[ "$line" == \[* ]]; then
			IFS=$'\n' read -r -d '' -a names < <(grep -o '\[[^]]*\]' <<<"$line" | tr -d '[]')
			groups=()
			for g in "${names[@]}"; do groups+=(--group "$g"); done
			continue
		fi
		kwriteconfig6 --file kdeglobals "${groups[@]}" --key "${line%%=*}" "${line#*=}"
	done <"$scheme"
fi
kwriteconfig6 --file kdeglobals --group Icons --key Theme 'breeze-dark'
# Without this, KDE apps outside Plasma ignore the colors above and apply BreezeLight.
kwriteconfig6 --file kdeglobals --group UiSettings --key ColorScheme 'RosePine'
