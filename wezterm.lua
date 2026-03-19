-- ══════════════════════════════════════════════════════════════════════════════
--  wezterm.lua  –  polished config
-- ══════════════════════════════════════════════════════════════════════════════
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
        -- ── Deep Ocean Midnight ─────────────────────────────────────────────
        --  Base: deep blue-black  |  Text: cool blue-white
        --  Cursor: warm amber     |  Selection: muted indigo wash
        --  ANSI: vivid but harmonious — each hue is distinct, never neon-washed
        return {
            foreground = "#ffffff", -- pure white
            background = "#0d1117", -- deep ink, not pure black

            cursor_bg = "#e6a817", -- warm amber — pops without screaming
            cursor_fg = "#0d1117",
            cursor_border = "#e6a817",

            selection_bg = "#1f3358", -- deep indigo wash
            selection_fg = "#e0e8f4",

            --               black      red        green      yellow
            --               blue       magenta    cyan       white
            ansi = {"#21262d", -- black   (dark panel)
            "#e05c6a", -- red     (coral-red, not neon)
            "#56d364", -- green   (fresh leaf)
            "#e3a84a", -- yellow  (warm amber — matches cursor)
            "#58a6ff", -- blue    (sky blue, GitHub accent)
            "#bc8cff", -- magenta (soft violet)
            "#39c5cf", -- cyan    (teal-cyan)
            "#ffffff" -- white
            },
            brights = {"#484f58", -- bright black  (visible grey)
            "#ff8090", -- bright red    (lighter coral)
            "#8be9a0", -- bright green  (mint)
            "#ffd07a", -- bright yellow (honey)
            "#91cbff", -- bright blue   (airy)
            "#d2aaff", -- bright magenta(lavender)
            "#72dfe8", -- bright cyan   (aqua)
            "#dde4ed" -- bright white  (near-white)
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
        -- ── Warm Parchment (light) ──────────────────────────────────────────
        --  Base: aged paper  |  Text: dark sepia ink
        --  Cursor: deep teal |  ANSI: ink-print palette — rich, not pastel
        return {
            foreground = "#2b2b2b",
            background = "#f5f0e8", -- warm parchment

            cursor_bg = "#007a87", -- deep teal
            cursor_fg = "#f5f0e8",
            cursor_border = "#007a87",

            selection_bg = "#c7dff7",
            selection_fg = "#1a1a1a",

            ansi = {"#d4cfc6", -- black   (warm light grey)
            "#c0392b", -- red     (deep crimson)
            "#1e8a4c", -- green   (forest)
            "#b8860b", -- yellow  (dark goldenrod)
            "#1a6faf", -- blue    (navy)
            "#7c3e8a", -- magenta (plum)
            "#007a87", -- cyan    (deep teal — matches cursor)
            "#2b2b2b" -- white   (ink)
            },
            brights = {"#b0a898", -- bright black
            "#e74c3c", -- bright red
            "#27ae60", -- bright green
            "#d4a017", -- bright yellow
            "#2980b9", -- bright blue
            "#9b59b6", -- bright magenta
            "#16a085", -- bright cyan
            "#1a1a1a" -- bright white
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
wezterm.on("update-right-status", function(window, pane)
    local dark = is_dark()
    local dim = dark and "#555555" or "#aaaaaa"
    local accent = dark and "#4fa3ff" or "#2475c8"
    local muted = dark and "#888888" or "#666666"

    -- Workspace name
    local ws = window:active_workspace()

    -- Battery (works on laptops; graceful no-op on desktop)
    local bat_text = ""
    local bat_ok, bat_list = pcall(wezterm.battery_info)
    if bat_ok and bat_list and bat_list[1] then
        local b = bat_list[1]
        local pct = math.floor(b.state_of_charge * 100)
        local icon = (b.state == "Charging") and "󱐋" or "󰁹"
        bat_text = string.format("  %s %d%%", icon, pct)
    end

    -- Clock
    local time = wezterm.strftime "  %H:%M"

    window:set_right_status(wezterm.format {{
        Foreground = {
            Color = dim
        }
    }, {
        Text = "  " .. ws
    }, {
        Foreground = {
            Color = muted
        }
    }, {
        Text = bat_text
    }, {
        Foreground = {
            Color = accent
        }
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

    -- Truncate if needed
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
    window:set_config_overrides{
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

-- Leader:  Ctrl+Space  (tap once, then press the chord within 1.5 s)
local LEADER = {
    key = "Space",
    mods = "CTRL",
    timeout_milliseconds = 1500
}

-- Quick-jump to tabs 1-9 (clean loop, no IIFE)
local alt_tabs = {}
for i = 1, 9 do
    alt_tabs[i] = {
        key = tostring(i),
        mods = "ALT",
        action = act.ActivateTab(i - 1)
    }
end

local keys =
    { -- ── Splits ─────────────────────────────────────────────────────────────
    {
        key = "d",
        mods = "CTRL|SHIFT",
        action = act.SplitHorizontal {
            domain = "CurrentPaneDomain"
        }
    }, {
        key = "e",
        mods = "CTRL|SHIFT",
        action = act.SplitVertical {
            domain = "CurrentPaneDomain"
        }
    },

    -- ── Pane navigation (Vim-style) ────────────────────────────────────────
    {
        key = "h",
        mods = "CTRL|SHIFT",
        action = act.ActivatePaneDirection "Left"
    }, {
        key = "l",
        mods = "CTRL|SHIFT",
        action = act.ActivatePaneDirection "Right"
    }, {
        key = "k",
        mods = "CTRL|SHIFT",
        action = act.ActivatePaneDirection "Up"
    }, {
        key = "j",
        mods = "CTRL|SHIFT",
        action = act.ActivatePaneDirection "Down"
    },

    -- ── Pane resize ────────────────────────────────────────────────────────
    {
        key = "LeftArrow",
        mods = "CTRL|SHIFT",
        action = act.AdjustPaneSize {"Left", 3}
    }, {
        key = "RightArrow",
        mods = "CTRL|SHIFT",
        action = act.AdjustPaneSize {"Right", 3}
    }, {
        key = "UpArrow",
        mods = "CTRL|SHIFT",
        action = act.AdjustPaneSize {"Up", 3}
    }, {
        key = "DownArrow",
        mods = "CTRL|SHIFT",
        action = act.AdjustPaneSize {"Down", 3}
    },

    -- ── Pane select (visual picker) ────────────────────────────────────────
    {
        key = "p",
        mods = "CTRL|SHIFT",
        action = act.PaneSelect {
            alphabet = "1234567890"
        }
    },

    -- ── Tabs ───────────────────────────────────────────────────────────────
    {
        key = "t",
        mods = "CTRL|SHIFT",
        action = act.SpawnTab "CurrentPaneDomain"
    }, {
        key = "w",
        mods = "CTRL|SHIFT",
        action = act.CloseCurrentTab {
            confirm = true
        }
    }, {
        key = "Tab",
        mods = "CTRL",
        action = act.ActivateTabRelative(1)
    }, {
        key = "Tab",
        mods = "CTRL|SHIFT",
        action = act.ActivateTabRelative(-1)
    },

    -- ── Copy / paste ───────────────────────────────────────────────────────
    {
        key = "c",
        mods = "CTRL|SHIFT",
        action = act.CopyTo "ClipboardAndPrimarySelection"
    }, {
        key = "v",
        mods = "CTRL|SHIFT",
        action = act.PasteFrom "Clipboard"
    },

    -- ── Search ─────────────────────────────────────────────────────────────
    {
        key = "f",
        mods = "CTRL|SHIFT",
        action = act.Search {
            CaseInSensitiveString = ""
        }
    },

    -- ── Scrollback ─────────────────────────────────────────────────────────
    {
        key = "k",
        mods = "CTRL",
        action = act.ClearScrollback "ScrollbackOnly"
    }, {
        key = "PageUp",
        mods = "SHIFT",
        action = act.ScrollByPage(-1)
    }, {
        key = "PageDown",
        mods = "SHIFT",
        action = act.ScrollByPage(1)
    },

    -- ── Zoom / full-screen ─────────────────────────────────────────────────
    {
        key = "z",
        mods = "CTRL|SHIFT",
        action = act.TogglePaneZoomState
    }, {
        key = "F11",
        action = act.ToggleFullScreen
    },

    -- ── Font size ──────────────────────────────────────────────────────────
    {
        key = "=",
        mods = "CTRL",
        action = act.IncreaseFontSize
    }, {
        key = "-",
        mods = "CTRL",
        action = act.DecreaseFontSize
    }, {
        key = "0",
        mods = "CTRL",
        action = act.ResetFontSize
    },

    -- ── Copy mode ──────────────────────────────────────────────────────────
    {
        key = "Enter",
        mods = "CTRL|SHIFT",
        action = act.ActivateCopyMode
    },

    -- ── Tab bar toggle ─────────────────────────────────────────────────────
    {
        key = "b",
        mods = "CTRL|SHIFT",
        action = act.EmitEvent "toggle-tab-bar"
    },

    -- ── Leader-based extras ────────────────────────────────────────────────
    -- Ctrl+Space → r  : reload config
    {
        key = "r",
        mods = "LEADER",
        action = act.ReloadConfiguration
    }, -- Ctrl+Space → s  : rename tab via prompt
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
    }, -- Ctrl+Space → c  : command palette
    {
        key = "c",
        mods = "LEADER",
        action = act.ActivateCommandPalette
    }, -- Ctrl+Space → q  : close pane (no confirm)
    {
        key = "q",
        mods = "LEADER",
        action = act.CloseCurrentPane {
            confirm = false
        }
    }}

-- Merge alt-tab jump keys
for _, v in ipairs(alt_tabs) do
    keys[#keys + 1] = v
end

-- ─────────────────────────────────────────────
--  Mouse bindings
-- ─────────────────────────────────────────────
local mouse_bindings = { -- Right-click → paste
{
    event = {
        Down = {
            streak = 1,
            button = "Right"
        }
    },
    mods = "NONE",
    action = act.PasteFrom "Clipboard"
}, -- Triple-click → select line
{
    event = {
        Down = {
            streak = 3,
            button = "Left"
        }
    },
    mods = "NONE",
    action = act.SelectTextAtMouseCursor "Line"
}, -- Ctrl+click → open hyperlink
{
    event = {
        Up = {
            streak = 1,
            button = "Left"
        }
    },
    mods = "CTRL",
    action = act.OpenLinkAtMouseCursor
}}

-- ─────────────────────────────────────────────
--  Copy-mode key table customisation
-- ─────────────────────────────────────────────
local copy_mode_keys = {{
    key = "Escape",
    mods = "NONE",
    action = act.CopyMode "Close"
}, {
    key = "q",
    mods = "NONE",
    action = act.CopyMode "Close"
}, {
    key = "h",
    mods = "NONE",
    action = act.CopyMode "MoveLeft"
}, {
    key = "l",
    mods = "NONE",
    action = act.CopyMode "MoveRight"
}, {
    key = "k",
    mods = "NONE",
    action = act.CopyMode "MoveUp"
}, {
    key = "j",
    mods = "NONE",
    action = act.CopyMode "MoveDown"
}, {
    key = "v",
    mods = "NONE",
    action = act.CopyMode {
        SetSelectionMode = "Cell"
    }
}, {
    key = "V",
    mods = "NONE",
    action = act.CopyMode {
        SetSelectionMode = "Line"
    }
}, {
    key = "y",
    mods = "NONE",
    action = act.Multiple {act.CopyTo "ClipboardAndPrimarySelection", act.CopyMode "Close"}
}, {
    key = "0",
    mods = "NONE",
    action = act.CopyMode "MoveToStartOfLine"
}, {
    key = "$",
    mods = "NONE",
    action = act.CopyMode "MoveToEndOfLineContent"
}, {
    key = "g",
    mods = "NONE",
    action = act.CopyMode "MoveToScrollbackTop"
}, {
    key = "G",
    mods = "NONE",
    action = act.CopyMode "MoveToScrollbackBottom"
}, {
    key = "f",
    mods = "NONE",
    action = act.CopyMode {
        JumpForward = {
            prev_char = false
        }
    }
}, {
    key = "F",
    mods = "NONE",
    action = act.CopyMode {
        JumpBackward = {
            prev_char = false
        }
    }
}}

-- ══════════════════════════════════════════════════════════════════════════════
--  Main config
-- ══════════════════════════════════════════════════════════════════════════════

-- ── Appearance ───────────────────────────────────────────────────────────────
cfg.colors = make_colors(is_dark())
cfg.color_scheme = nil -- manual colors above

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
cfg.macos_window_background_blur = 24

-- ── Tab bar ──────────────────────────────────────────────────────────────────
cfg.enable_tab_bar = false -- toggle with Ctrl+Shift+B
cfg.use_fancy_tab_bar = false
cfg.tab_bar_at_bottom = true
cfg.tab_max_width = 36
cfg.hide_tab_bar_if_only_one_tab = true
cfg.show_new_tab_button_in_tab_bar = false

-- ── Performance ──────────────────────────────────────────────────────────────
cfg.animation_fps = 120
cfg.max_fps = 120
cfg.front_end = "WebGpu" -- fall back to "OpenGL" if issues

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
-- Extra rule: highlight bare GitHub repo paths  user/repo
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
cfg.quote_dropped_files = "Posix" -- drag-and-drop quotes paths correctly

-- ── Bindings ─────────────────────────────────────────────────────────────────
cfg.leader = LEADER
cfg.keys = keys
cfg.mouse_bindings = mouse_bindings
cfg.key_tables = {
    copy_mode = copy_mode_keys
}

return cfg
