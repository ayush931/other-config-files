local wezterm = require "wezterm"
local act = wezterm.action
local cfg = wezterm.config_builder() -- gives better error messages

-- ─────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────

--- Always use dark mode to keep white text and prevent light-theme flash.
local function is_dark()
    return true
end

--- Trim a path to the last N segments (default 2).
local function short_path(p, n)
    n = n or 2
    local segments = {}
    for s in (p or ""):gmatch "[^/\\]+" do
        segments[#segments + 1] = s
    end
    local out = {}
    for i = math.max(1, #segments - n + 1), #segments do
        out[#out + 1] = segments[i]
    end
    return table.concat(out, "/")
end

-- ─────────────────────────────────────────────
--  Process → icon lookup
-- ─────────────────────────────────────────────
local ICONS = {
    vim = "󰕷 ",
    nvim = "󰕷 ",
    bash = " ",
    zsh = " ",
    fish = " ",
    sh = " ",
    python = "󰌠 ",
    python3 = "󰌠 ",
    node = "󰎙 ",
    npm = "󰎙 ",
    yarn = "󰎙 ",
    git = "󰊢 ",
    ssh = "󰣀 ",
    docker = "󰡨 ",
    htop = " ",
    btop = " ",
    top = " ",
    make = " ",
    cargo = "󱘗 ",
    rust = "󱘗 ",
    lua = "󰢱 "
}

local function process_icon(name)
    if not name then
        return "  "
    end
    local base = name:match "([^/\\]+)$" or name
    return ICONS[base] or "  "
end

-- ─────────────────────────────────────────────
--  Color palettes  (dark + light)
-- ─────────────────────────────────────────────
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

            ansi = {
                "#21262d",
                "#e05c6a",
                "#56d364",
                "#e3a84a",
                "#58a6ff",
                "#bc8cff",
                "#39c5cf",
                "#ffffff"
            },
            brights = {
                "#484f58",
                "#ff8090",
                "#8be9a0",
                "#ffd07a",
                "#91cbff",
                "#d2aaff",
                "#72dfe8",
                "#dde4ed"
            },

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
    else
        return {
            foreground = "#2b2b2b",
            background = "#f5f0e8",

            cursor_bg = "#007a87",
            cursor_fg = "#f5f0e8",
            cursor_border = "#007a87",

            selection_bg = "#c7dff7",
            selection_fg = "#1a1a1a",

            ansi = {
                "#d4cfc6",
                "#c0392b",
                "#1e8a4c",
                "#b8860b",
                "#1a6faf",
                "#7c3e8a",
                "#007a87",
                "#2b2b2b"
            },
            brights = {
                "#b0a898",
                "#e74c3c",
                "#27ae60",
                "#d4a017",
                "#2980b9",
                "#9b59b6",
                "#16a085",
                "#1a1a1a"
            },

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
end

-- ─────────────────────────────────────────────
--  Status bar  (right side)
-- ─────────────────────────────────────────────
wezterm.on("update-right-status", function(window)
    local dark = is_dark()
    local dim = dark and "#555555" or "#aaaaaa"
    local accent = dark and "#4fa3ff" or "#2475c8"
    local muted = dark and "#888888" or "#666666"

    local ws = window:active_workspace()

    local bat_text = ""
    local bat_ok, bat_list = pcall(wezterm.battery_info)
    if bat_ok and bat_list and bat_list[1] then
        local b = bat_list[1]
        local pct = math.floor(b.state_of_charge * 100)
        local icon = (b.state == "Charging") and "󱐋" or "󰁹"
        bat_text = string.format("  %s %d%%", icon, pct)
    end

    local time = wezterm.strftime "  %H:%M"

    window:set_right_status(wezterm.format {{
        Foreground = {Color = dim}
    }, {
        Text = "  " .. ws
    }, {
        Foreground = {Color = muted}
    }, {
        Text = bat_text
    }, {
        Foreground = {Color = accent}
    }, {
        Text = time .. "  "
    }})
end)

-- ─────────────────────────────────────────────
--  Tab title
-- ─────────────────────────────────────────────
wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
    local pane = tab.active_pane
    local proc = pane.foreground_process_name
    local icon = process_icon(proc)

    local cwd = ""
    if pane.current_working_dir then
        local p = pane.current_working_dir.file_path or tostring(pane.current_working_dir)
        cwd = short_path(p, 2)
    end

    local title = icon .. cwd
    local idx = tab.tab_index + 1
    local zoomed = tab.active_pane.is_zoomed and "  " or ""

    local label = string.format(" %d: %s%s ", idx, title, zoomed)
    if #label > max_width then
        label = string.format(" %d: %s%s ", idx, cwd:sub(-(max_width - 6)), zoomed)
    end
    return label
end)

-- ─────────────────────────────────────────────
--  Tab-bar toggle
-- ─────────────────────────────────────────────
local tab_bar_visible = false
wezterm.on("toggle-tab-bar", function(window)
    tab_bar_visible = not tab_bar_visible
    window:set_config_overrides {
        enable_tab_bar = tab_bar_visible
    }
end)

-- ─────────────────────────────────────────────
--  Auto dark/light
-- ─────────────────────────────────────────────
wezterm.on("window-config-reloaded", function(window)
    local overrides = window:get_config_overrides() or {}
    overrides.colors = make_colors(is_dark())
    window:set_config_overrides(overrides)
end)

-- ─────────────────────────────────────────────
--  Keybindings
-- ─────────────────────────────────────────────
local LEADER = {
    key = "Space",
    mods = "CTRL",
    timeout_milliseconds = 1500
}

local alt_tabs = {}
for i = 1, 9 do
    alt_tabs[i] = {
        key = tostring(i),
        mods = "ALT",
        action = act.ActivateTab(i - 1)
    }
end

local keys = {
    {
        key = "d",
        mods = "CTRL|SHIFT",
        action = act.SplitHorizontal {domain = "CurrentPaneDomain"}
    },
    {
        key = "e",
        mods = "CTRL|SHIFT",
        action = act.SplitVertical {domain = "CurrentPaneDomain"}
    },
    {
        key = "h",
        mods = "CTRL|SHIFT",
        action = act.ActivatePaneDirection "Left"
    },
    {
        key = "l",
        mods = "CTRL|SHIFT",
        action = act.ActivatePaneDirection "Right"
    },
    {
        key = "k",
        mods = "CTRL|SHIFT",
        action = act.ActivatePaneDirection "Up"
    },
    {
        key = "j",
        mods = "CTRL|SHIFT",
        action = act.ActivatePaneDirection "Down"
    },
    {
        key = "LeftArrow",
        mods = "CTRL|SHIFT",
        action = act.AdjustPaneSize {"Left", 3}
    },
    {
        key = "RightArrow",
        mods = "CTRL|SHIFT",
        action = act.AdjustPaneSize {"Right", 3}
    },
    {
        key = "UpArrow",
        mods = "CTRL|SHIFT",
        action = act.AdjustPaneSize {"Up", 3}
    },
    {
        key = "DownArrow",
        mods = "CTRL|SHIFT",
        action = act.AdjustPaneSize {"Down", 3}
    },
    {
        key = "p",
        mods = "CTRL|SHIFT",
        action = act.PaneSelect {alphabet = "1234567890"}
    },
    {
        key = "t",
        mods = "CTRL|SHIFT",
        action = act.SpawnTab "CurrentPaneDomain"
    },
    {
        key = "w",
        mods = "CTRL|SHIFT",
        action = act.CloseCurrentTab {confirm = true}
    },
    {
        key = "Tab",
        mods = "CTRL",
        action = act.ActivateTabRelative(1)
    },
    {
        key = "Tab",
        mods = "CTRL|SHIFT",
        action = act.ActivateTabRelative(-1)
    },
    {
        key = "c",
        mods = "CTRL|SHIFT",
        action = act.CopyTo "ClipboardAndPrimarySelection"
    },
    {
        key = "v",
        mods = "CTRL|SHIFT",
        action = act.PasteFrom "Clipboard"
    },
    {
        key = "f",
        mods = "CTRL|SHIFT",
        action = act.Search {CaseInSensitiveString = ""}
    },
    {
        key = "k",
        mods = "CTRL",
        action = act.ClearScrollback "ScrollbackOnly"
    },
    {
        key = "PageUp",
        mods = "SHIFT",
        action = act.ScrollByPage(-1)
    },
    {
        key = "PageDown",
        mods = "SHIFT",
        action = act.ScrollByPage(1)
    },
    {
        key = "z",
        mods = "CTRL|SHIFT",
        action = act.TogglePaneZoomState
    },
    {
        key = "F11",
        action = act.ToggleFullScreen
    },
    {
        key = "=",
        mods = "CTRL",
        action = act.IncreaseFontSize
    },
    {
        key = "-",
        mods = "CTRL",
        action = act.DecreaseFontSize
    },
    {
        key = "0",
        mods = "CTRL",
        action = act.ResetFontSize
    },
    {
        key = "Enter",
        mods = "CTRL|SHIFT",
        action = act.ActivateCopyMode
    },
    {
        key = "b",
        mods = "CTRL|SHIFT",
        action = act.EmitEvent "toggle-tab-bar"
    },
    {
        key = "r",
        mods = "LEADER",
        action = act.ReloadConfiguration
    },
    {
        key = "s",
        mods = "LEADER",
        action = act.PromptInputLine {
            description = "Rename tab:",
            action = wezterm.action_callback(function(window, _, line)
                if line then
                    window:active_tab():set_title(line)
                end
            end)
        }
    },
    {
        key = "c",
        mods = "LEADER",
        action = act.ActivateCommandPalette
    },
    {
        key = "q",
        mods = "LEADER",
        action = act.CloseCurrentPane {confirm = false}
    }
}

for _, v in ipairs(alt_tabs) do
    keys[#keys + 1] = v
end

-- ─────────────────────────────────────────────
--  Mouse bindings
-- ─────────────────────────────────────────────
local mouse_bindings = {
    {
        event = {
            Down = {
                streak = 1,
                button = "Right"
            }
        },
        mods = "NONE",
        action = act.PasteFrom "Clipboard"
    },
    {
        event = {
            Down = {
                streak = 3,
                button = "Left"
            }
        },
        mods = "NONE",
        action = act.SelectTextAtMouseCursor "Line"
    },
    {
        event = {
            Up = {
                streak = 1,
                button = "Left"
            }
        },
        mods = "CTRL",
        action = act.OpenLinkAtMouseCursor
    }
}

-- ─────────────────────────────────────────────
--  Copy-mode key table customisation
-- ─────────────────────────────────────────────
local copy_mode_keys = {
    {
        key = "Escape",
        mods = "NONE",
        action = act.CopyMode "Close"
    },
    {
        key = "q",
        mods = "NONE",
        action = act.CopyMode "Close"
    },
    {
        key = "h",
        mods = "NONE",
        action = act.CopyMode "MoveLeft"
    },
    {
        key = "l",
        mods = "NONE",
        action = act.CopyMode "MoveRight"
    },
    {
        key = "k",
        mods = "NONE",
        action = act.CopyMode "MoveUp"
    },
    {
        key = "j",
        mods = "NONE",
        action = act.CopyMode "MoveDown"
    },
    {
        key = "v",
        mods = "NONE",
        action = act.CopyMode {SetSelectionMode = "Cell"}
    },
    {
        key = "V",
        mods = "NONE",
        action = act.CopyMode {SetSelectionMode = "Line"}
    },
    {
        key = "y",
        mods = "NONE",
        action = act.Multiple {act.CopyTo "ClipboardAndPrimarySelection", act.CopyMode "Close"}
    },
    {
        key = "0",
        mods = "NONE",
        action = act.CopyMode "MoveToStartOfLine"
    },
    {
        key = "$",
        mods = "NONE",
        action = act.CopyMode "MoveToEndOfLineContent"
    },
    {
        key = "g",
        mods = "NONE",
        action = act.CopyMode "MoveToScrollbackTop"
    },
    {
        key = "G",
        mods = "NONE",
        action = act.CopyMode "MoveToScrollbackBottom"
    },
    {
        key = "f",
        mods = "NONE",
        action = act.CopyMode {
            JumpForward = {
                prev_char = false
            }
        }
    },
    {
        key = "F",
        mods = "NONE",
        action = act.CopyMode {
            JumpBackward = {
                prev_char = false
            }
        }
    }
}

-- ══════════════════════════════════════════════════════════════════════════════
--  Main config
-- ══════════════════════════════════════════════════════════════════════════════

cfg.default_prog = {"/usr/bin/zsh", "-l"}

-- Fedora/Linux stability settings.
cfg.front_end = "OpenGL"
cfg.enable_wayland = false

-- ── Appearance ───────────────────────────────────────────────────────────────
cfg.colors = make_colors(is_dark())
cfg.color_scheme = nil

cfg.background = {{
    source = {
        File = wezterm.home_dir .. "/Downloads/pic2.jpg"
    },
    hsb = {
        brightness = 0.30,
        hue = 1.0,
        saturation = 0.9
    },
    opacity = 1.0
}}

-- ── Font ─────────────────────────────────────────────────────────────────────
cfg.font = wezterm.font_with_fallback {{
    family = "JetBrains Mono",
    weight = "Regular"
}, {
    family = "Fira Code",
    weight = "Regular"
}, "monospace"}
cfg.font_size = 11.5
cfg.harfbuzz_features = {"calt=1", "clig=1", "liga=1"}

-- ── Cursor ───────────────────────────────────────────────────────────────────
cfg.default_cursor_style = "BlinkingBlock"
cfg.cursor_blink_rate = 530
cfg.cursor_blink_ease_in = "Constant"
cfg.cursor_blink_ease_out = "Constant"

-- ── Window ───────────────────────────────────────────────────────────────────
cfg.window_background_opacity = 0.97
cfg.window_decorations = "RESIZE"
cfg.window_padding = {
    left = 14,
    right = 14,
    top = 12,
    bottom = 8
}

-- ── Tab bar ──────────────────────────────────────────────────────────────────
cfg.enable_tab_bar = false
cfg.use_fancy_tab_bar = false
cfg.tab_bar_at_bottom = true
cfg.tab_max_width = 36
cfg.hide_tab_bar_if_only_one_tab = true
cfg.show_new_tab_button_in_tab_bar = false

-- ── Performance ──────────────────────────────────────────────────────────────
cfg.animation_fps = 120
cfg.max_fps = 120

-- ── Scrollback ───────────────────────────────────────────────────────────────
cfg.scrollback_lines = 20000
cfg.enable_scroll_bar = false

-- ── Bell ─────────────────────────────────────────────────────────────────────
cfg.audible_bell = "Disabled"
cfg.visual_bell = {
    fade_in_duration_ms = 60,
    fade_out_duration_ms = 60,
    target = "CursorColor"
}

-- ── Initial size ─────────────────────────────────────────────────────────────
cfg.initial_cols = 130
cfg.initial_rows = 34

-- ── Hyperlinks ───────────────────────────────────────────────────────────────
cfg.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(cfg.hyperlink_rules, {
    regex = [[\b[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+\b]],
    format = "https://github.com/$0"
})

-- ── Misc ─────────────────────────────────────────────────────────────────────
cfg.automatically_reload_config = true
cfg.check_for_updates = false
cfg.status_update_interval = 1000
cfg.exit_behavior = "Close"
cfg.window_close_confirmation = "NeverPrompt"
cfg.quote_dropped_files = "Posix"
cfg.adjust_window_size_when_changing_font_size = false

-- ── Bindings ─────────────────────────────────────────────────────────────────
cfg.leader = LEADER
cfg.keys = keys
cfg.mouse_bindings = mouse_bindings
cfg.key_tables = {
    copy_mode = copy_mode_keys
}

return cfg
