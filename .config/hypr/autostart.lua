-- --------------------------------------------------
--    _         _____  ___  __  _____  _      __  _____
--   /_\  /\ /\/__   \/___\/ _\/__   \/_\    /__\/__   \
--  //_\\/ / \ \ / /\//  //\ \   / /\//_\\  / \//  / /\/
-- /  _  \ \_/ // / / \_// _\ \ / / /  _  \/ _  \ / /
-- \_/ \_/\___/ \/  \___/  \__/ \/  \_/ \_/\/ \_/ \/
-- --------------------------------------------------

hl.on("hyprland.start", function()
	-- Bootstrap
	hl.exec_cmd("~/dotfiles/scripts/general/bootstrap.sh")

	-- Notification daemon
	hl.exec_cmd("mako")

	-- Status Bar
	hl.exec_cmd("~/dotfiles/.config/waybar/launch.sh")

	-- Wallpaper Engine
	hl.exec_cmd("~/dotfiles/scripts/hypr/autostart/hyprpaper.sh")

	-- Starts a cliphist session
	hl.exec_cmd("clipse -listen")

	-- Make sure that xdg-desktop-portal-hyprland can get the required variables on startup.
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	-- Start KDE Connect on startup
	hl.exec_cmd("kdeconnect-indicator")
end)
