local wezterm = require("wezterm")
local act = wezterm.action

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Fix block rendering :/
config.front_end = "WebGpu"

-- Color config
config.color_scheme = "Gruvbox dark, soft (base16)"

-- Font config
config.font = wezterm.font("JetBrainsMono Nerd Font")
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

-- Function to detect if running under Wayland
local function is_wayland()
	return wezterm.target_triple:find("linux") and os.getenv("WAYLAND_DISPLAY") ~= nil
end

-- Configure clipboard handling based on display server
local function paste_action()
	if false then
		return wezterm.action_callback(function(window, pane)
			-- Use wl-paste to get clipboard content
			local clipboard_data = io.popen("wl-paste"):read("*a")

			-- Remove only one trailing newline if it exists
			if clipboard_data:sub(-1) == "\n" then
				clipboard_data = clipboard_data:sub(1, -2)
			end

			window:perform_action(act.SendString(clipboard_data), pane)
		end)
	else
		return act.PasteFrom("Clipboard")
	end
end

-- Keybindings
config.keys = {
	{
		key = "v",
		mods = "CTRL",
		action = paste_action(),
	},

	-- Remap C-CR and S-CR to their actual keys again
	{ key = "Enter", mods = "SHIFT", action = act.SendString("\x1b[13;2u") },
	{ key = "Enter", mods = "CTRL", action = act.SendString("\x1b[13;5u") },
}

return config
