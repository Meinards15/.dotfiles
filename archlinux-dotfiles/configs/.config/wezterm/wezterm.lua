local wezterm = require "wezterm"

-- Wezterm Configuration Setup
local config = {
    color_scheme = "Tokyo Night Storm",
    font = wezterm.font "JetBrains Mono",
    enable_tab_bar = false,
    exit_behavior = "Close",
    enable_wayland = true,
    window_close_confirmation = "NeverPrompt",
}


return config
