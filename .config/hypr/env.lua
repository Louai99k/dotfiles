-- --------------------------------------------------
--    __    __
--   /__\/\ \ \/\   /\
--  /_\ /  \/ /\ \ / /
-- //__/ /\  /  \ V /
-- \__/\_\ \/    \_/
-- --------------------------------------------------

-- GTK: Use wayland.
hl.env("GDK_BACKEND", "wayland")

-- Tells Qt based applications to pick your theme from qt6ct.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Tell Qt applications to use the Wayland backend
hl.env("QT_QPA_PLATFORM", "wayland")

-- Tell Electron to adapt to wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

hl.env("EDITOR", "nvim")

-- XDG Specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- The cursor theme
hl.env("XCURSOR_THEME", "breeze_cursors")
