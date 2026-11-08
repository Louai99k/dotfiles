-- --------------------------------------------------
--    ___   _____    __  ___  __
--   / __\  \_   \/\ \ \/   \/ _\
--  /__\//   / /\/  \/ / /\ /\ \
-- / \/  \/\/ /_/ /\  / /_// _\ \
-- \_____/\____/\_\ \/___,'  \__/
-- --------------------------------------------------

-- I define it here so I can change it any time from one place
local mainMod = "SUPER"

-- --------------------------------------------------
-- Default app commands
-- --------------------------------------------------
local browser = "firefox"
local terminal = "kitty"
local fileManager = "dolphin"
local menu = "wofi -S drun"

-- --------------------------------------------------
-- Bind apps
-- --------------------------------------------------
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))

-- --------------------------------------------------
-- Bind actions
-- --------------------------------------------------
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + DELETE", hl.dsp.exec_cmd("wlogout"))
hl.bind("SUPER + V", hl.dsp.exec_cmd(terminal .. ' --class clipse -e "clipse"'))

-- --------------------------------------------------
-- Multi Media
-- --------------------------------------------------
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +1%"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -1%"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

-- --------------------------------------------------
-- Workspace changing + move apps to workspace
-- --------------------------------------------------
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- --------------------------------------------------
-- Hyprland Utils
-- --------------------------------------------------
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + UP", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + DOWN", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + LEFT", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + RIGHT", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- --------------------------------------------------
-- Bind Miscs
-- --------------------------------------------------
hl.bind("Print", hl.dsp.exec_cmd("~/dotfiles/scripts/misc/screenshot.sh"))
