{ pkgs, osConfig, ... }:

{
  imports = [ ./niri-keybinds.nix ];

  programs.niri.settings = {
    prefer-no-csd = true;

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
        width = 2;
      };
      focus-ring.enable = false;
    };

    spawn-at-startup = [
      { command = [ "${pkgs.awww}/bin/awww-daemon" ]; }
      { command = [ "sh" "-c" "sleep 1 && ${pkgs.awww}/bin/awww img ${osConfig.stylix.image}" ]; }
      { command = [ "wl-paste" "--type" "text" "--watch" "cliphist" "store" ]; }
      { command = [ "wl-paste" "--type" "image" "--watch" "cliphist" "store" ]; }
      { command = [ "systemctl" "--user" "start" "hyprpolkitagent" ]; }
    ];
  };
}
