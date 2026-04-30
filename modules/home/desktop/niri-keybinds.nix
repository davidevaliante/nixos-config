{ config, ... }:

let
  isNoctalia = config.mySystem.desktop.shell == "noctalia";

  launcherSpawn   = if isNoctalia then [ "noctalia-shell" "ipc" "call" "launcher" "toggle" ]                          else [ "fuzzel" ];
  notifySpawn     = if isNoctalia then [ "noctalia-shell" "ipc" "call" "notifications" "toggleHistory" ]              else [ "swaync-client" "-t" "-sw" ];
  lockSpawn       = if isNoctalia then [ "noctalia-shell" "ipc" "call" "lockScreen" "lock" ]                          else [ "hyprlock" ];
  sessionSpawn    = if isNoctalia then [ "noctalia-shell" "ipc" "call" "sessionMenu" "toggle" ]                       else [ "wlogout" ];
  cheatsheetSpawn = if isNoctalia then [ "noctalia-shell" "ipc" "call" "plugin" "togglePanel" "keybind-cheatsheet" ]  else [ "keybind-help" ];
  windowSwitchSpawn = if isNoctalia then [ "noctalia-shell" "ipc" "call" "launcher" "windows" ]                     else [ "niri-window-switcher" ];

  screenshotRegion = "grim -g \"$(slurp)\" - | satty --filename - --output-filename ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png --copy-command wl-copy";
  screenshotFull   = "grim - | satty --filename - --output-filename ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png --copy-command wl-copy";
in
{
  programs.niri.settings.binds = {
    "Mod+Return"   = { action.spawn = [ "kitty" ];                 hotkey-overlay.title = "Terminal"; };
    "Mod+B"        = { action.spawn = [ "google-chrome-stable" ];  hotkey-overlay.title = "Browser"; };
    "Mod+Space"    = { action.spawn = launcherSpawn;               hotkey-overlay.title = "Launcher"; };
    "Mod+Q"        = { action.close-window = [ ];                  hotkey-overlay.title = "Close window"; };
    "Mod+Shift+Q"  = { action.quit = [ ];                          hotkey-overlay.title = "Quit niri"; };
    "Mod+Escape"   = { action.spawn = lockSpawn;                   hotkey-overlay.title = "Lock screen"; };
    "Mod+Alt+L"    = { action.spawn = lockSpawn;                   hotkey-overlay.title = "Lock screen"; };
    "Mod+N"        = { action.spawn = notifySpawn;                 hotkey-overlay.title = "Notification history"; };
    "Mod+T"        = { action.spawn = [ "theme-switch" ];          hotkey-overlay.title = "Switch theme"; };
    "Mod+Shift+E"  = { action.spawn = sessionSpawn;                hotkey-overlay.title = "Session menu"; };
    "Mod+Slash"    = { action.spawn = cheatsheetSpawn;             hotkey-overlay.title = "Keybind cheatsheet"; };
    "Mod+O"        = { action.toggle-overview = [ ];               hotkey-overlay.title = "Toggle overview"; };
    "Mod+G"        = { action.spawn = windowSwitchSpawn;           hotkey-overlay.title = "Find window"; };
    "Mod+Shift+R"  = { action.spawn = [ "niri-workspace-rename" ]; hotkey-overlay.title = "Rename workspace"; };

    "Mod+H"          = { action.focus-column-left = [ ];           hotkey-overlay.title = "Focus column left"; };
    "Mod+L"          = { action.focus-column-right = [ ];          hotkey-overlay.title = "Focus column right"; };
    "Mod+J"          = { action.focus-window-down = [ ];           hotkey-overlay.title = "Focus window down"; };
    "Mod+K"          = { action.focus-window-up = [ ];             hotkey-overlay.title = "Focus window up"; };
    "Alt+Tab"        = { action.focus-column-right-or-first = [ ]; hotkey-overlay.title = "Cycle columns forward"; };
    "Alt+Shift+Tab"  = { action.focus-column-left-or-last = [ ];   hotkey-overlay.title = "Cycle columns backward"; };
    "Mod+Tab"        = { action.focus-column-right-or-first = [ ]; hotkey-overlay.title = "Cycle columns forward"; };
    "Mod+Shift+Tab"  = { action.focus-column-left-or-last = [ ];   hotkey-overlay.title = "Cycle columns backward"; };

    "Mod+Shift+H"  = { action.move-column-left = [ ];   hotkey-overlay.title = "Move column left"; };
    "Mod+Shift+L"  = { action.move-column-right = [ ];  hotkey-overlay.title = "Move column right"; };
    "Mod+Shift+J"  = { action.move-window-down = [ ];   hotkey-overlay.title = "Move window down"; };
    "Mod+Shift+K"  = { action.move-window-up = [ ];     hotkey-overlay.title = "Move window up"; };

    "Mod+1" = { action.focus-workspace = [ 1 ]; hotkey-overlay.title = "Focus workspace 1"; };
    "Mod+2" = { action.focus-workspace = [ 2 ]; hotkey-overlay.title = "Focus workspace 2"; };
    "Mod+3" = { action.focus-workspace = [ 3 ]; hotkey-overlay.title = "Focus workspace 3"; };
    "Mod+4" = { action.focus-workspace = [ 4 ]; hotkey-overlay.title = "Focus workspace 4"; };
    "Mod+5" = { action.focus-workspace = [ 5 ]; hotkey-overlay.title = "Focus workspace 5"; };
    "Mod+6" = { action.focus-workspace = [ 6 ]; hotkey-overlay.title = "Focus workspace 6"; };
    "Mod+7" = { action.focus-workspace = [ 7 ]; hotkey-overlay.title = "Focus workspace 7"; };
    "Mod+8" = { action.focus-workspace = [ 8 ]; hotkey-overlay.title = "Focus workspace 8"; };
    "Mod+9" = { action.focus-workspace = [ 9 ]; hotkey-overlay.title = "Focus workspace 9"; };

    "Mod+Shift+1" = { action.move-column-to-workspace = [ 1 ]; hotkey-overlay.title = "Move column to workspace 1"; };
    "Mod+Shift+2" = { action.move-column-to-workspace = [ 2 ]; hotkey-overlay.title = "Move column to workspace 2"; };
    "Mod+Shift+3" = { action.move-column-to-workspace = [ 3 ]; hotkey-overlay.title = "Move column to workspace 3"; };
    "Mod+Shift+4" = { action.move-column-to-workspace = [ 4 ]; hotkey-overlay.title = "Move column to workspace 4"; };
    "Mod+Shift+5" = { action.move-column-to-workspace = [ 5 ]; hotkey-overlay.title = "Move column to workspace 5"; };
    "Mod+Shift+6" = { action.move-column-to-workspace = [ 6 ]; hotkey-overlay.title = "Move column to workspace 6"; };
    "Mod+Shift+7" = { action.move-column-to-workspace = [ 7 ]; hotkey-overlay.title = "Move column to workspace 7"; };
    "Mod+Shift+8" = { action.move-column-to-workspace = [ 8 ]; hotkey-overlay.title = "Move column to workspace 8"; };
    "Mod+Shift+9" = { action.move-column-to-workspace = [ 9 ]; hotkey-overlay.title = "Move column to workspace 9"; };

    "Mod+R"        = { action.switch-preset-column-width = [ ];    hotkey-overlay.title = "Cycle column width"; };
    "Mod+F"        = { action.maximize-column = [ ];               hotkey-overlay.title = "Maximize column"; };
    "Mod+Shift+F"  = { action.fullscreen-window = [ ];             hotkey-overlay.title = "Fullscreen window"; };
    "Mod+V"        = { action.toggle-window-floating = [ ];        hotkey-overlay.title = "Toggle floating"; };
    "Mod+W"        = { action.toggle-column-tabbed-display = [ ];  hotkey-overlay.title = "Toggle tabbed column"; };

    "Mod+S"        = { action.spawn-sh = [ screenshotRegion ]; hotkey-overlay.title = "Screenshot region"; };
    "Mod+Shift+S"  = { action.spawn-sh = [ screenshotFull ];   hotkey-overlay.title = "Screenshot full screen"; };

    "XF86AudioRaiseVolume"  = { action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+" ];   hotkey-overlay.title = "Volume up"; };
    "XF86AudioLowerVolume"  = { action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-" ];   hotkey-overlay.title = "Volume down"; };
    "XF86AudioMute"         = { action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ]; hotkey-overlay.title = "Mute toggle"; };
    "XF86MonBrightnessUp"   = { action.spawn = [ "brightnessctl" "set" "5%+" ];                         hotkey-overlay.title = "Brightness up"; };
    "XF86MonBrightnessDown" = { action.spawn = [ "brightnessctl" "set" "5%-" ];                         hotkey-overlay.title = "Brightness down"; };
  };
}
