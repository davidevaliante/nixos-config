{ pkgs, lib, config, ... }:

let
  c = config.lib.stylix.colors;
in
{
  home.packages = with pkgs; [ nerd-fonts._0xproto ];

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
      window_padding_width = "0 8";
      placement_strategy = "center";

      # ── Tab bar ──
      tab_bar_edge = "bottom";
      tab_bar_style = "separator";   # flat & minimal; alternatives: fade, powerline
      tab_bar_min_tabs = 2;          # hide when only 1 tab (wezterm equivalent)
      tab_separator = " ┇ ";
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
      active_tab_foreground   #${c.base00}
      active_tab_background   #${c.base0D}
      inactive_tab_foreground #${c.base04}
      inactive_tab_background #${c.base01}
    '';
  };
}
