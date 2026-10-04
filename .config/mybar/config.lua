-- mybar configuration. The bar reloads automatically when you save this file.
-- Keep the table in a global called `Config`.

Config = {
    height        = 26,                         -- pixels; also the space reserved for the bar
    padding       = 12,                         -- left/right margin
    padding_left  = 0,                          -- override one side (default: padding)
    padding_right = 18,
    spacing       = 23,                         -- gap between modules (per module: spacing = px)
    font          = "Iosevka NFP:pixelsize=18", -- fontconfig name + fcft attributes
    bg            = "#141617",
    fg            = "#d4be98",

    -- Where bare plugin names are looked up (default: <this dir>/modules, ./modules,
    -- /usr/local/lib/mybar/modules).
    -- modules_dir = "modules",

    -- Each entry is either a plugin
    --   "battery"                    a name   -> <modules_dir>/battery.so
    --   "modules/battery.so"         a path   -> relative to this file, then to the cwd
    -- or a table with options:
    --   { path = "battery", interval = 10, low = 20, color = "#a6e3a1" }
    -- Options understood by every module: path, interval (seconds, 0 = events only),
    -- color, spacing (gap after it, px).
    -- Everything else is read by the plugin itself (see the header of modules/NAME.c).
    modules = {
        left = {
            { path = "workspaces", format = "{name} {icons}", persistent = 5,
              icon_size = 16, icon_theme = "Adwaita",
              pad_left = 9, pad_right = 9, fg = "#928374", active_bg = "none", spacing = 5 },
            { path = "window", format = "[{title}]", max_chars = 60 },
        },
        center = {},
        right = {
            { path = "volume", format = "volume: {pct}%", muted_format = "muted" },
            { path = "battery", device = "BAT1", interval = 15, format = "battery: {pct}%",
              low = 25, low_color = "#ea6962" },
            "language",
            { path = "network", wifi_format = "network: {name}", ethernet_format = "network: {name}",
              offline_format = "offline" },
            { path = "datetime", format = "%H:%M" },
        },
    },
}
