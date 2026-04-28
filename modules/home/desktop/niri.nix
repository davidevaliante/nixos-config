{ pkgs, osConfig, ... }:

{
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

    binds = {
      "Mod+Return".action.spawn = [ "kitty" ];
      "Mod+B".action.spawn = [ "firefox" ];
      "Mod+Space".action.spawn = [ "fuzzel" ];
      "Mod+Q".action.close-window = [ ];
      "Mod+Shift+Q".action.quit = [ ];
      "Mod+Escape".action.spawn = [ "hyprlock" ];
      "Mod+Alt+L".action.spawn = [ "hyprlock" ];
      "Mod+N".action.spawn = [ "swaync-client" "-t" "-sw" ];
      "Mod+T".action.spawn = [ "theme-switch" ];
      "Mod+Shift+E".action.spawn = [ "wlogout" ];
      "Mod+Slash".action.spawn = [ "keybind-help" ];

      "Mod+H".action.focus-column-left = [ ];
      "Mod+L".action.focus-column-right = [ ];
      "Mod+J".action.focus-window-down = [ ];
      "Mod+K".action.focus-window-up = [ ];

      "Mod+Shift+H".action.move-column-left = [ ];
      "Mod+Shift+L".action.move-column-right = [ ];
      "Mod+Shift+J".action.move-window-down = [ ];
      "Mod+Shift+K".action.move-window-up = [ ];

      "Mod+1".action.focus-workspace = [ 1 ];
      "Mod+2".action.focus-workspace = [ 2 ];
      "Mod+3".action.focus-workspace = [ 3 ];
      "Mod+4".action.focus-workspace = [ 4 ];
      "Mod+5".action.focus-workspace = [ 5 ];
      "Mod+6".action.focus-workspace = [ 6 ];
      "Mod+7".action.focus-workspace = [ 7 ];
      "Mod+8".action.focus-workspace = [ 8 ];
      "Mod+9".action.focus-workspace = [ 9 ];

      "Mod+Shift+1".action.move-column-to-workspace = [ 1 ];
      "Mod+Shift+2".action.move-column-to-workspace = [ 2 ];
      "Mod+Shift+3".action.move-column-to-workspace = [ 3 ];
      "Mod+Shift+4".action.move-column-to-workspace = [ 4 ];
      "Mod+Shift+5".action.move-column-to-workspace = [ 5 ];
      "Mod+Shift+6".action.move-column-to-workspace = [ 6 ];
      "Mod+Shift+7".action.move-column-to-workspace = [ 7 ];
      "Mod+Shift+8".action.move-column-to-workspace = [ 8 ];
      "Mod+Shift+9".action.move-column-to-workspace = [ 9 ];

      "Mod+R".action.switch-preset-column-width = [ ];
      "Mod+F".action.maximize-column = [ ];
      "Mod+Shift+F".action.fullscreen-window = [ ];
      "Mod+V".action.toggle-window-floating = [ ];
      "Mod+W".action.toggle-column-tabbed-display = [ ];

      "Mod+S".action.spawn-sh = [ "grim -g \"$(slurp)\" - | satty --filename - --output-filename ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png --copy-command wl-copy" ];
      "Mod+Shift+S".action.spawn-sh = [ "grim - | satty --filename - --output-filename ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png --copy-command wl-copy" ];

      "XF86AudioRaiseVolume".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+" ];
      "XF86AudioLowerVolume".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" ];
      "XF86AudioMute".action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ];
      "XF86MonBrightnessUp".action.spawn = [ "brightnessctl" "set" "5%+" ];
      "XF86MonBrightnessDown".action.spawn = [ "brightnessctl" "set" "5%-" ];
    };
  };
}
