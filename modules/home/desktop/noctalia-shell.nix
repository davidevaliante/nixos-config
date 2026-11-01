{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.mySystem.desktop;
  active = cfg.shell == "noctalia";

  # Region screenshot → Litterbox (1h temp host) → Google Lens by URL.
  # Lens has no public unauthenticated upload endpoint that's stable from a
  # shell client, so we round-trip through a temp host the same way
  # Snipping-Lens/QuickSnip do.
  lensSearch = pkgs.writeShellScriptBin "lens-search" ''
    set -eu
    img=$(${pkgs.coreutils}/bin/mktemp --suffix=.png)
    trap 'rm -f "$img"' EXIT
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" "$img"
    url=$(${pkgs.curl}/bin/curl -fsS \
      -F "reqtype=fileupload" \
      -F "time=1h" \
      -F "fileToUpload=@$img" \
      https://litterbox.catbox.moe/resources/internals/api.php) || url=""
    if [ -z "$url" ] || [ "''${url#http}" = "$url" ]; then
      ${pkgs.libnotify}/bin/notify-send -u critical "Lens search failed" "Upload to Litterbox failed"
      exit 1
    fi
    ${pkgs.xdg-utils}/bin/xdg-open "https://lens.google.com/uploadbyurl?url=$url"
  '';

  # hyprpicker -a copies the hex to the Wayland clipboard and prints it.
  # We surface the value as a notification so the user knows the pick landed.
  colorPick = pkgs.writeShellScriptBin "color-pick" ''
    set -eu
    color=$(${pkgs.hyprpicker}/bin/hyprpicker -a -f hex || true)
    if [ -n "''${color:-}" ]; then
      ${pkgs.libnotify}/bin/notify-send "Color picked" "$color"
    fi
  '';

  # slurp prints the selection geometry; we format it human-readably, copy
  # to the Wayland clipboard, and surface it as a notification so the user
  # can read the dimensions without looking at a terminal. ESC during the
  # drag makes slurp exit non-zero — `|| exit 0` swallows that quietly.
  pixelMeasure = pkgs.writeShellScriptBin "pixel-measure" ''
    set -u
    geom=$(${pkgs.slurp}/bin/slurp -f '%wx%h @ %x,%y' 2>/dev/null) || exit 0
    [ -n "$geom" ] || exit 0
    printf '%s' "$geom" | ${pkgs.wl-clipboard}/bin/wl-copy
    ${pkgs.libnotify}/bin/notify-send "Region measured" "$geom"
  '';

  # noctalia 5.x is a native binary (mainProgram `noctalia`) and hot-reloads
  # its TOML config via inotify, so an HM rebuild no longer needs a restart to
  # pick up config changes. This is a convenience helper for the rare case a
  # full restart is wanted (e.g. after a package bump). makeWrapper execs the
  # real binary as `.noctalia-wrapped`, so we match both the wrapper and the
  # wrapped process.
  noctaliaReload = pkgs.writeShellScriptBin "noctalia-reload" ''
    set -u
    ${pkgs.procps}/bin/pkill -x noctalia 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -x .noctalia-wrapp 2>/dev/null || true
    for _ in 1 2 3 4 5; do
      ${pkgs.procps}/bin/pgrep -x noctalia >/dev/null 2>&1 || break
      sleep 0.2
    done
    setsid noctalia </dev/null >/dev/null 2>&1 &
  '';
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  # noctalia 5.x rewrote its config as a validated TOML stack (`config.toml`),
  # dropped the declarative `plugins` option (plugins are now Luau and managed
  # at runtime via `noctalia msg plugins …`), and moved theming into the
  # stylix target. We therefore let stylix drive the palette/mode/font/opacity
  # (see modules/noctalia/hm.nix in the stylix input, which auto-activates once
  # this module is imported) and only set the handful of behavioural keys that
  # aren't theme-derived. `checkConfig` (default true) runs `noctalia config
  # validate` at build time, so an unknown key fails the build rather than
  # silently no-op'ing at runtime.
  programs.noctalia = lib.mkIf active {
    enable = true;

    settings = {
      # Force 0xProto Nerd Font. Stylix's noctalia target sets
      # `shell.font_family` to its sans-serif (Inter); mkForce wins so the shell
      # always uses 0xProto regardless of the active stylix theme.
      shell.font_family = lib.mkForce "0xProto Nerd Font";

      # Use noctalia's built-in polkit authentication agent for GUI privilege
      # prompts. Replaces hyprpolkitagent, whose 0.2.0 (hyprtoolkit/OpenGL)
      # rewrite SIGABRTs on startup under niri. noctalia is our shell under both
      # niri and Hyprland, so its native agent covers both.
      shell.polkit_agent = true;

      # Fully transparent bar background. v5 dropped v4's `useSeparateOpacity`
      # flag — the bar opacity is now always independent of panel opacity, so
      # this single key is all that's needed.
      bar.main = {
        background_opacity = 0.0;
        # Per-widget "capsule" — the grey rounded pill behind each widget that
        # keeps icons readable over a transparent bar (the v4 look). v5 defaults
        # it off, so re-enable it; fill/opacity use the theme's surface role, so
        # it follows stylix.
        capsule = true;
        # Right-hand widget section. v5 widget ids are plain lowercase strings
        # (no `{ id = …; }` objects, no `plugin:` prefix). `clipboard` is v5's
        # built-in clipboard history (replaces the old `clipper` plugin) and
        # `network` carries the VPN indicator (there is no standalone VPN
        # widget anymore — see [widget.network] below).
        end = [
          "tray"
          "notifications"
          "clipboard"
          "network"
          "battery"
          "volume"
          "bluetooth"
          "brightness"
          "control-center"
          "session"
        ];
      };

      # Panel placement. v5 dropped v4's `useSeparateOpacity`, so an *attached*
      # panel inherits the bar's `background_opacity` — with our transparent bar
      # (0.0) the attached control-center/session/wallpaper panels render with a
      # see-through background (cards keep their own color). Making them
      # `floating` decouples them: floating panels use `transparency_mode`
      # (`solid` → opaque). `open_near_click_*` anchors a click-opened panel to
      # the clicked widget instead of screen/bar centre. The launcher stays
      # floating+centred (it's keyboard-driven via Mod+Space).
      shell.panel = {
        control_center_placement = "floating";
        session_placement = "floating";
        wallpaper_placement = "floating";
        open_near_click_control_center = true;
        open_near_click_clipboard = true;
        open_near_click_session = true;
        open_near_click_wallpaper = true;
      };

      # Surface the NetworkManager VPN state inside the network widget. `both`
      # shows the VPN label alongside the network label (replacing the old
      # standalone "VPN" pill).
      widget.network = {
        vpn_status = "both";
        show_vpn_label = true;
      };

      # Idle pipeline: screen off at 15 min, lock at 30 min, no suspend.
      # v5 models each idle stage as a named `[idle.behavior.<name>]` table with
      # its own timeout/action/enabled. Timeouts are absolute (measured from the
      # last input event), not additive.
      idle.behavior = {
        "screen-off" = {
          timeout = 15 * 60;
          action = "screen_off";
          enabled = true;
        };
        lock = {
          timeout = 30 * 60;
          action = "lock";
          enabled = true;
        };
      };
    };
  };

  # The lens-search / color-pick / pixel-measure utilities were bar-widget
  # plugins in v4; v5 can't load QML plugins, so they live on as standalone
  # shell scripts surfaced through the launcher (desktop entries below). The
  # old keybind-cheatsheet and clipper plugins are dropped (clipboard history
  # is now a built-in widget).
  home.packages = lib.mkIf active [
    noctaliaReload
    lensSearch
    colorPick
    pixelMeasure
    pkgs.hyprpicker
    pkgs.wl-clipboard
  ];

  # Surface the helper scripts in fuzzel (and any other XDG launcher) so the
  # user can invoke them without a dedicated keybind. NoDisplay=false so they
  # show up in the launcher; Terminal=false so they don't pop a kitty window.
  xdg.desktopEntries = lib.mkIf active {
    lens-search = {
      name = "Lens Search";
      comment = "Region screenshot → Google Lens";
      exec = "lens-search";
      icon = "search";
      terminal = false;
      categories = [ "Utility" "Graphics" ];
    };
    color-pick = {
      name = "Color Picker";
      comment = "Pick a pixel color from the screen";
      exec = "color-pick";
      icon = "color-picker";
      terminal = false;
      categories = [ "Utility" "Graphics" ];
    };
    pixel-measure = {
      name = "Pixel Measure";
      comment = "Measure a screen region in pixels";
      exec = "pixel-measure";
      icon = "measure";
      terminal = false;
      categories = [ "Utility" "Graphics" ];
    };
  };

  # Autostart. The binary is `noctalia` in v5 (v4 shipped `noctalia-shell`).
  # Its default logout already quits the compositor natively (niri msg action
  # quit / hyprctl dispatch exit) before falling back to loginctl, so the v4
  # GDM-hang workaround that overrode the logout command is no longer needed.
  wayland.windowManager.hyprland.settings.exec-once = lib.mkIf active [ "noctalia" ];

  programs.niri.settings.spawn-at-startup = lib.mkIf active [ { command = [ "noctalia" ]; } ];
}
