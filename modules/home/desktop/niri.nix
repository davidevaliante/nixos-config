{ pkgs, lib, osConfig, ... }:

let
  host = osConfig.networking.hostName;
in

{
  imports = [ ./niri-keybinds.nix ];

  programs.niri.settings = {
    prefer-no-csd = true;
    hotkey-overlay.skip-at-startup = true;

    # Per-host outputs. Without an explicit mode, niri picks the EDID-
    # preferred entry — which on helium's ultrawide is 60Hz even though
    # the panel does 144Hz. Hydrogen has different displays; leave its
    # outputs empty here and add a block when needed.
    outputs = lib.optionalAttrs (host == "helium") {
      "DP-1" = {
        mode = { width = 3440; height = 1440; refresh = 144.000; };
        position = { x = 0; y = 0; };
        scale = 1.0;
      };
      "DP-2" = {
        mode = { width = 1920; height = 1080; refresh = 60.000; };
        position = { x = 3440; y = 0; };
        scale = 1.0;
      };
    };

    input = {
      keyboard.xkb.layout = "us";
      touchpad = {
        natural-scroll = true;
        tap = true;
      };
      mouse.accel-speed = if host == "helium" then -0.5 else 0.0;
      focus-follows-mouse.enable = false;
    };

    layout = {
      gaps = 12;
      center-focused-column = "never";
      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 0.5; }
        { proportion = 2.0 / 3.0; }
      ];
      default-column-width.proportion = 0.5;
      border = {
        enable = true;
        width = 3;
      };
      focus-ring.enable = false;
    };

    window-rules = [
      {
        geometry-corner-radius =
          let r = 8.0; in
          { top-left = r; top-right = r; bottom-left = r; bottom-right = r; };
        clip-to-geometry = true;
      }
      {
        matches = [
          { app-id = "^kitty$"; }
          { app-id = "^google-chrome$"; }
          { app-id = "^Slack$"; }
        ];
        open-maximized = true;
      }
      {
        matches = [ { app-id = "^kitty-floating$"; } ];
        open-floating = true;
        default-column-width = { fixed = 1000; };
        default-window-height = { fixed = 600; };
      }
    ];

    spawn-at-startup = [
      { command = [ "${pkgs.awww}/bin/awww-daemon" ]; }
      { command = [ "sh" "-c" "sleep 1 && ${pkgs.awww}/bin/awww img ${osConfig.stylix.image}" ]; }
      { command = [ "wl-paste" "--type" "text" "--watch" "cliphist" "store" ]; }
      { command = [ "wl-paste" "--type" "image" "--watch" "cliphist" "store" ]; }
      { command = [ "systemctl" "--user" "start" "hyprpolkitagent" ]; }
    ];
  };
}
