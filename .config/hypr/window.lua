-- --------------------------------------------------
--  __    __ _           _
-- / / /\ \ (_)_ __   __| | _____      __
-- \ \/  \/ / | '_ \ / _` |/ _ \ \ /\ / /
--  \  /\  /| | | | | (_| | (_) \ V  V /
--   \/  \/ |_|_| |_|\__,_|\___/ \_/\_/
-- --------------------------------------------------

hl.window_rule({
	name = "clipse-float",
	match = { class = "(clipse)" },

	-- ensure you have a floating window class set if you want this behavior
	float = true,
	-- set the size of the window as necessary
	size = "600 500",
	-- kitty asks to be maximized on launch, which would cover the screen
	suppress_event = "maximize fullscreen",
	center = true,
})
