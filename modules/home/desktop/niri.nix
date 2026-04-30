{ pkgs, osConfig, ... }:

{
  imports = [ ./niri-keybinds.nix ];

  programs.niri.settings = {
    prefer-no-csd = true;
    hotkey-overlay.skip-at-startup = true;

    input = {
      keyboard.xkb.layout = "us";
      touchpad = {
        natural-scroll = true;
        tap = true;
      };
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
