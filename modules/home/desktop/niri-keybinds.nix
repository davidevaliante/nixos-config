{ config, ... }:

let
  isNoctalia = config.mySystem.desktop.shell == "noctalia";

  launcherSpawn   = if isNoctalia then [ "noctalia-shell" "ipc" "call" "launcher" "toggle" ]                          else [ "fuzzel" ];
  notifySpawn     = if isNoctalia then [ "noctalia-shell" "ipc" "call" "notifications" "toggleHistory" ]              else [ "swaync-client" "-t" "-sw" ];
  lockSpawn       = if isNoctalia then [ "noctalia-shell" "ipc" "call" "lockScreen" "lock" ]                          else [ "hyprlock" ];
  sessionSpawn    = if isNoctalia then [ "noctalia-shell" "ipc" "call" "sessionMenu" "toggle" ]                       else [ "wlogout" ];
  cheatsheetSpawn = if isNoctalia then [ "noctalia-shell" "ipc" "call" "plugin" "togglePanel" "keybind-cheatsheet" ]  else [ "keybind-help" ];
in
{
  programs.niri.settings.binds = {
    "Mod+Return".action.spawn = [ "kitty" ];
    "Mod+B".action.spawn = [ "google-chrome-stable" ];
    "Mod+Space".action.spawn = launcherSpawn;
    "Mod+Q".action.close-window = [ ];
    "Mod+Shift+Q".action.quit = [ ];
    "Mod+Escape".action.spawn = lockSpawn;
    "Mod+Alt+L".action.spawn = lockSpawn;
    "Mod+N".action.spawn = notifySpawn;
    "Mod+T".action.spawn = [ "theme-switch" ];
    "Mod+Shift+E".action.spawn = sessionSpawn;
    "Mod+Slash".action.spawn = cheatsheetSpawn;

    "Mod+H".action.focus-column-left = [ ];
    "Mod+L".action.focus-column-right = [ ];
    "Mod+Tab".action.focus-column-right-or-first = [ ];
    "Mod+Shift+Tab".action.focus-column-left-or-last = [ ];
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
}
