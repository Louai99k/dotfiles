#!/bin/bash
# Renders every color config and the wallpaper link from ~/.config/theme/palette.conf,
# then applies the settings that can't live in files (gsettings, kdeglobals).
# Runs at every Hyprland start via bootstrap.sh.
#
# Usage: theme.sh [--reload]   --reload also refreshes running apps.

set -uo pipefail

DOT="$HOME/dotfiles"
THEME="$DOT/.config/theme"
TEMPLATES="$THEME/templates"
GTK_THEME="dotfiles"
GTK_SRC="$THEME/gtk3"
GTK_OUT="$DOT/.local/share/themes/$GTK_THEME"

# --- Palette ------------------------------------------------------------------

declare -A pal
while IFS='=' read -r key value; do
	[[ -z "$key" || "$key" == \#* ]] && continue
	pal[$key]="$value"
done <"$THEME/palette.conf"

# accent may name another color
if [[ -n "${pal[${pal[accent]}]:-}" ]]; then
	pal[accent]="${pal[${pal[accent]}]}"
fi

sed_script=""
for key in "${!pal[@]}"; do
	[[ "$key" == wallpaper ]] && continue
	hex="${pal[$key],,}"
	if [[ ! "$hex" =~ ^[0-9a-f]{6}$ ]]; then
		echo "theme.sh: $key=$hex in palette.conf is not a 6-digit hex color" >&2
		exit 1
	fi
	pal[$key]="$hex"
	rgb="$((16#${hex:0:2})),$((16#${hex:2:2})),$((16#${hex:4:2}))"
	sed_script+="s/{{$key}}/$hex/g;s/{{${key}_rgb}}/$rgb/g;"
done

# --- Templates ----------------------------------------------------------------
# templates/<path> renders to ~/dotfiles/<path>. Outputs are gitignored.

while IFS= read -r -d '' template; do
	out="$DOT/${template#"$TEMPLATES"/}"
	mkdir -p "$(dirname "$out")"
	sed "$sed_script" "$template" >"$out.tmp" && mv "$out.tmp" "$out"
	if grep -q '{{[a-z_]*}}' "$out"; then
		echo "theme.sh: unknown placeholder in $template: $(grep -o '{{[a-z_]*}}' "$out" | sort -u | tr '\n' ' ')" >&2
	fi
	if ! git -C "$DOT" check-ignore -q "$out"; then
		echo "theme.sh: $out is generated but not in .gitignore" >&2
	fi
done < <(find "$TEMPLATES" -type f -print0)

# --- GTK3 theme ---------------------------------------------------------------
# The upstream Rosé Pine theme has its colors compiled into gtk.gresource.
# Swap its palette for ours and recompile. Only exact palette colors are
# swapped; shades upstream derived from them keep their Rosé Pine values.

declare -A upstream=(
	[base]=191724 [surface]=1f1d2e [overlay]=26233a [muted]=6e6a86 [subtle]=908caa
	[text]=e0def4 [love]=eb6f92 [gold]=f6c177 [rose]=ebbcba [pine]=31748f
	[foam]=9ccfd8 [iris]=c4a7e7 [hl_low]=21202e [hl_med]=403d52 [hl_high]=524f67
)

stamp="$(cat "$THEME/palette.conf" "$GTK_SRC/gtk-3.20/gtk.gresource" "$0" | sha256sum | cut -d' ' -f1)"
gtk_rebuilt=false
if [[ "$(cat "$GTK_OUT/.stamp" 2>/dev/null)" != "$stamp" ]]; then
	work="$(mktemp -d)"
	gtk_sed=""
	for role in "${!upstream[@]}"; do
		gtk_sed+="s/#${upstream[$role]}/#@@${role}@@/gI;"
	done
	for role in "${!upstream[@]}"; do
		new="${pal[$role]}"
		[[ "$role" == iris ]] && new="${pal[accent]}" # upstream uses iris as its accent
		gtk_sed+="s/#@@${role}@@/#$new/g;"
	done

	xml='<?xml version="1.0" encoding="UTF-8"?><gresources><gresource prefix="/">'
	while IFS= read -r resource; do
		mkdir -p "$work/files$(dirname "$resource")"
		gresource extract "$GTK_SRC/gtk-3.20/gtk.gresource" "$resource" >"$work/files$resource"
		[[ "$resource" == *.css || "$resource" == *.svg ]] && sed -i "$gtk_sed" "$work/files$resource"
		xml+="<file>${resource#/}</file>"
	done < <(gresource list "$GTK_SRC/gtk-3.20/gtk.gresource")
	xml+='</gresource></gresources>'
	echo "$xml" >"$work/gtk.gresource.xml"

	rm -rf "$GTK_OUT"
	mkdir -p "$GTK_OUT/gtk-3.20"
	cp "$GTK_SRC/index.theme" "$GTK_SRC/LICENSE" "$GTK_OUT/"
	cp "$GTK_SRC/gtk-3.20/gtk.css" "$GTK_SRC/gtk-3.20/gtk-dark.css" "$GTK_OUT/gtk-3.20/"
	if glib-compile-resources --sourcedir="$work/files" --target="$GTK_OUT/gtk-3.20/gtk.gresource" "$work/gtk.gresource.xml"; then
		echo "$stamp" >"$GTK_OUT/.stamp"
		gtk_rebuilt=true
	fi
	rm -rf "$work"
fi

# --- Wallpaper ----------------------------------------------------------------

wallpaper="$DOT/${pal[wallpaper]}"
if [[ -f "$wallpaper" ]]; then
	ln -sfn "$wallpaper" "$THEME/wallpaper"
else
	echo "theme.sh: wallpaper $wallpaper not found" >&2
fi

# --- gsettings ----------------------------------------------------------------
# GTK reads these from dconf on Wayland, which isn't a file stow can track.

gs() { gsettings set org.gnome.desktop.interface "$@"; }

gs gtk-theme "$GTK_THEME"
gs icon-theme 'breeze-dark'
gs cursor-theme 'breeze_cursors'
gs cursor-size 24
gs font-name 'JetBrainsMono Nerd Font 11'
gs document-font-name 'JetBrainsMono Nerd Font 11'
gs monospace-font-name 'JetBrainsMono Nerd Font Mono 11'
gs color-scheme 'prefer-dark'

# --- KDE apps -----------------------------------------------------------------
# KDE apps (Dolphin, ...) take colors and icons from kdeglobals, which they
# also write to, so it isn't stowed. Merge the rendered scheme into it instead.

scheme="$HOME/.local/share/color-schemes/Palette.colors"
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
kwriteconfig6 --file kdeglobals --group UiSettings --key ColorScheme 'Palette'

# --- Reload running apps ------------------------------------------------------

if [[ "${1:-}" == --reload ]]; then
	pkill -SIGUSR2 -x waybar
	makoctl reload 2>/dev/null
	pkill -SIGUSR1 -x kitty
	if pgrep -x hyprpaper >/dev/null; then
		pkill -x hyprpaper
		setsid -f hyprpaper >/dev/null 2>&1
	fi
	# Running GTK apps only re-read a theme when its name changes.
	if $gtk_rebuilt; then
		gs gtk-theme 'Adwaita'
		gs gtk-theme "$GTK_THEME"
	fi
fi
