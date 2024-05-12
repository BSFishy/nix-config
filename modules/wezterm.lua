local wezterm = require("wezterm")
local act = wezterm.action

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Color config
config.color_scheme = "Gruvbox dark, soft (base16)"

-- Font config
config.font = wezterm.font("JetBrains Mono")
config.font_size = 13
config.line_height = 1.2

-- Tab config
config.hide_tab_bar_if_only_one_tab = true

-- Window config
config.window_padding = {
	left = "1cell",
	right = "1cell",
	top = "0.5cell",
	bottom = "0.5cell",
}

-- Keybindings
config.keys = {
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
}

return config
