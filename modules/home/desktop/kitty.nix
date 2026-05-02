{ pkgs, lib, config, ... }:

let
  c = config.lib.stylix.colors;
in
{
  home.packages = with pkgs; [ nerd-fonts._0xproto ];

  # Replace the cat icon with a generic terminal glyph from the active icon
  # theme. User-level desktop entries override the kitty package's own.
  xdg.desktopEntries.kitty = {
    name = "kitty";
    genericName = "Terminal emulator";
    comment = "Fast, feature-rich, GPU based terminal";
    exec = "kitty";
    icon = "utilities-terminal";
    terminal = false;
    type = "Application";
    startupNotify = true;
    categories = [ "System" "TerminalEmulator" ];
  };

  programs.kitty = {
    enable = true;

    settings = {
      # ── Font (from wezterm) ──
      # Override stylix's JetBrainsMono with 0xProto for kitty specifically.
      # Other apps (waybar, fuzzel) keep JetBrainsMono via stylix.
      font_family = lib.mkForce "0xProto Nerd Font Mono";

      # ── Behaviour ──
      enable_audio_bell = false;
      confirm_os_window_close = 0;
      hide_window_decorations = "yes";
      window_padding_width = "8 8";
      placement_strategy = "center";

      # ── Tab bar ──
      tab_bar_edge = "bottom";
      tab_bar_style = "fade";        # color fade between tabs; flat when bgs match
      tab_bar_min_tabs = 2;          # hide when only 1 tab
      tab_fade = "1 1 1 1";          # uniform fade weights so colors don't gradient
      # Python format-spec on the template enforces a min width: {title:^14}
      # centers in 14 chars, padding short titles like `~` with spaces while
      # still expanding for longer paths. No truncation — kitty handles that
      # via tab_title_max_length if needed.
      tab_title_template = "{title:^14}";
      active_tab_font_style   = "bold";
      inactive_tab_font_style = "normal";
      # NOTE: tab colors are set in `extraConfig` below — same stylix
      # include-overrides-settings issue as `cursor`.

      # ── Cursor ──
      cursor_shape = "block";
      cursor_blink_interval = 0;     # don't blink — matches wezterm default
      shell_integration = "enabled";
      # NOTE: cursor is set in `extraConfig` below, NOT here. Stylix
      # appends a base16 color file via `include` *after* programs.kitty
      # settings, so anything set here for `cursor` gets overridden by
      # stylix's `cursor #<foreground>` (white). extraConfig + mkAfter
      # lands after the include.

      # ── Misc QoL ──
      copy_on_select = "no";
      strip_trailing_spaces = "smart";
      scrollback_lines = 10000;
      visual_bell_duration = "0.0";
    };

    keybindings = {
      "ctrl+shift+v" = "paste_from_clipboard";
      "ctrl+shift+c" = "copy_to_clipboard";
    };

    # Must come after stylix's `include base16-...conf` line; mkAfter
    # ensures it's the last block in kitty.conf so the cursor override
    # actually wins.
    extraConfig = lib.mkAfter ''
      cursor                  #${c.base09}
      cursor_text_color       #${c.base00}
      # Active tab = green text, inactive = muted gray.
      # All three backgrounds (active cell, inactive cell, tab-bar gutter)
      # are pinned to the terminal bg so the tab area is visually flat —
      # otherwise stylix's defaults leave the tab_bar_background slightly
      # different from the per-tab backgrounds.
      active_tab_foreground   #${c.base0B}
      active_tab_background   #${c.base00}
      inactive_tab_foreground #${c.base03}
      inactive_tab_background #${c.base00}
      tab_bar_background      #${c.base00}
      tab_bar_margin_color    #${c.base00}
    '';
  };
}
