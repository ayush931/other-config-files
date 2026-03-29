local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

local function is_dark()
    return true
end

local function make_colors(dark)
    if dark then
        return {
            foreground = "#ffffff",
            background = "#0d1117",
            cursor_bg = "#e6a817",
            cursor_fg = "#0d1117",
            cursor_border = "#e6a817",
            selection_bg = "#1f3358",
            selection_fg = "#e0e8f4",
            ansi = {"#21262d", "#e05c6a", "#56d364", "#e3a84a", "#58a6ff", "#bc8cff", "#39c5cf", "#ffffff"},
            brights = {"#484f58", "#ff8090", "#8be9a0", "#ffd07a", "#91cbff", "#d2aaff", "#72dfe8", "#dde4ed"},
            tab_bar = {
                background = "#090d12",
                active_tab = {
                    bg_color = "#161b22",
                    fg_color = "#c9d1d9",
                    intensity = "Bold"
                },
                inactive_tab = {
                    bg_color = "#090d12",
                    fg_color = "#3d444d"
                },
                inactive_tab_hover = {
                    bg_color = "#0d1117",
                    fg_color = "#768390"
                },
                new_tab = {
                    bg_color = "#090d12",
                    fg_color = "#3d444d"
                },
                new_tab_hover = {
                    bg_color = "#0d1117",
                    fg_color = "#768390"
                }
            }
        }
    end

    return {
        foreground = "#2b2b2b",
        background = "#f5f0e8",
        cursor_bg = "#007a87",
        cursor_fg = "#f5f0e8",
        cursor_border = "#007a87",
        selection_bg = "#c7dff7",
        selection_fg = "#1a1a1a",
        ansi = {"#d4cfc6", "#c0392b", "#1e8a4c", "#b8860b", "#1a6faf", "#7c3e8a", "#007a87", "#2b2b2b"},
        brights = {"#b0a898", "#e74c3c", "#27ae60", "#d4a017", "#2980b9", "#9b59b6", "#16a085", "#1a1a1a"},
        tab_bar = {
            background = "#e8e0d0",
            active_tab = {
                bg_color = "#f5f0e8",
                fg_color = "#2b2b2b",
                intensity = "Bold"
            },
            inactive_tab = {
                bg_color = "#e8e0d0",
                fg_color = "#9a9080"
            },
            inactive_tab_hover = {
                bg_color = "#ede8dc",
                fg_color = "#555045"
            },
            new_tab = {
                bg_color = "#e8e0d0",
                fg_color = "#9a9080"
            },
            new_tab_hover = {
                bg_color = "#ede8dc",
                fg_color = "#555045"
            }
        }
    }
end

local function short_path(p, n)
    n = n or 2
    local segments = {}
    for s in (p or ""):gmatch("[^/\\]+") do
        segments[#segments + 1] = s
    end
    local out = {}
    for i = math.max(1, #segments - n + 1), #segments do
        out[#out + 1] = segments[i]
    end
    return table.concat(out, "/")
end

wezterm.on("update-right-status", function(window)
    local dark = is_dark()
    local dim = dark and "#555555" or "#aaaaaa"
    local accent = dark and "#4fa3ff" or "#2475c8"

    local ws = window:active_workspace()
    local time = wezterm.strftime("  %H:%M")

    window:set_right_status(wezterm.format({{
        Foreground = {
            Color = dim
        }
    }, {
        Text = "  " .. ws
    }, {
        Foreground = {
            Color = accent
        }
    }, {
        Text = time .. "  "
    }}))
end)

wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
    local pane = tab.active_pane
    local cwd = ""
    if pane.current_working_dir then
        local p = pane.current_working_dir.file_path or tostring(pane.current_working_dir)
        cwd = short_path(p, 2)
    end

    local idx = tab.tab_index + 1
    local label = string.format(" %d: %s ", idx, cwd ~= "" and cwd or "shell")
    if #label > max_width then
        local available = math.max(1, max_width - 6)
        label = string.format(" %d: %s ", idx, cwd:sub(-available))
    end
    return label
end)

-- Fedora + GNOME friendly terminal defaults.
-- Avoid known crash paths on some Mesa/Wayland stacks.
config.enable_wayland = false
config.front_end = "OpenGL"

-- Typography
config.font = wezterm.font_with_fallback({"Fira Code"})
config.font_size = 11
config.line_height = 1.08
config.harfbuzz_features = {"calt=1", "clig=1", "liga=1"}

-- Window and visuals
config.window_decorations = "RESIZE"
config.window_padding = {
    left = 14,
    right = 14,
    top = 12,
    bottom = 8
}
config.window_background_opacity = 0.97
config.macos_window_background_blur = 0
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 36
config.animation_fps = 120
config.max_fps = 120

config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 530
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

-- Optional background image (safe: only applied if file exists).
local bg_image = wezterm.home_dir .. "/Downloads/pic2.jpg"
local bg_file = io.open(bg_image, "r")
if bg_file then
    bg_file:close()
    config.background = {{
        source = {
            File = bg_image
        },
        hsb = {
            brightness = 0.30,
            hue = 1.0,
            saturation = 0.9
        },
        opacity = 1.0
    }}
end

-- Scrollback and behavior
config.scrollback_lines = 20000
config.enable_scroll_bar = false
config.audible_bell = "Disabled"
config.visual_bell = {
    fade_in_duration_ms = 60,
    fade_out_duration_ms = 60,
    target = "CursorColor"
}
config.adjust_window_size_when_changing_font_size = false
config.automatically_reload_config = true
config.native_macos_fullscreen_mode = false
config.window_close_confirmation = "NeverPrompt"
config.status_update_interval = 1000
config.check_for_updates = false
config.quote_dropped_files = "Posix"

config.initial_cols = 130
config.initial_rows = 34

config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
    regex = [[\b[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+\b]],
    format = "https://github.com/$0"
})

-- Colors (custom palette keeps this portable across installs).
config.colors = make_colors(is_dark())

-- Leader key: Ctrl+a (tmux-like)
config.leader = {
    key = "a",
    mods = "CTRL",
    timeout_milliseconds = 1000
}

config.keys = { -- Split panes
{
    key = "|",
    mods = "LEADER|SHIFT",
    action = act.SplitHorizontal({
        domain = "CurrentPaneDomain"
    })
}, {
    key = "-",
    mods = "LEADER",
    action = act.SplitVertical({
        domain = "CurrentPaneDomain"
    })
}, -- Move between panes (vim-style)
{
    key = "h",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Left")
}, {
    key = "j",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Down")
}, {
    key = "k",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Up")
}, {
    key = "l",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Right")
}, -- Resize panes
{
    key = "H",
    mods = "LEADER|SHIFT",
    action = act.AdjustPaneSize({"Left", 5})
}, {
    key = "J",
    mods = "LEADER|SHIFT",
    action = act.AdjustPaneSize({"Down", 3})
}, {
    key = "K",
    mods = "LEADER|SHIFT",
    action = act.AdjustPaneSize({"Up", 3})
}, {
    key = "L",
    mods = "LEADER|SHIFT",
    action = act.AdjustPaneSize({"Right", 5})
}, -- Tabs
{
    key = "c",
    mods = "LEADER",
    action = act.SpawnTab("CurrentPaneDomain")
}, {
    key = "n",
    mods = "LEADER",
    action = act.ActivateTabRelative(1)
}, {
    key = "p",
    mods = "LEADER",
    action = act.ActivateTabRelative(-1)
}, {
    key = "x",
    mods = "LEADER",
    action = act.CloseCurrentPane({
        confirm = true
    })
}, -- Copy mode and search
{
    key = "[",
    mods = "LEADER",
    action = act.ActivateCopyMode
}, {
    key = "/",
    mods = "LEADER",
    action = act.Search({
        CaseSensitiveString = ""
    })
}}

-- Launch menu entries common on Fedora systems.
config.launch_menu = {{
    label = "Bash",
    args = {"bash", "-l"}
}, {
    label = "Zsh",
    args = {"zsh", "-l"}
}}

return config
