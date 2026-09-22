-- Personal geometry applies to every theme; colors come from the active theme.
hl.config({
  general = { gaps_in = 3, gaps_out = 6, border_size = 2 },
  decoration = {
    rounding = 0,
    shadow = { enabled = true, range = 18, render_power = 3, color = "rgba(00000035)" },
    blur = { enabled = true, size = 6, passes = 3, new_optimizations = true, ignore_opacity = true },
  },
})

-- Only blur shell surfaces, not the wallpaper, lock session, or every layer.
-- Ignore the low-alpha full-screen scrim so blur stays behind the glass cards.
hl.layer_rule({
  match = { namespace = "^(omarchy-bar|omarchy-menu|omarchy-keyboard-panel|omarchy-notifications|omarchy-osd|omarchy-polkit|omarchy-clipboard|omarchy-emojis)$" },
  blur = true,
  ignore_alpha = 0.3,
})
