{ pkgs, ... }:

let
  binds = [
    "Super+Return            kitty terminal"
    "Super+B                 google chrome"
    "Super+Space             fuzzel app launcher"
    "Super+T                 theme switcher"
    "Super+N                 swaync panel toggle"
    "Super+Q                 close window"
    "Super+Shift+Q           exit compositor"
    "Super+Shift+E           wlogout (lock/reboot/shutdown)"
    "Super+Escape            lock screen (hyprlock)"
    "Super+Alt+L             lock screen (fallback)"
    "Super+/                 this cheatsheet"
    ""
    "── focus / move ──"
    "Super+H J K L           focus left/down/up/right"
    "Super+Shift+H J K L     move window in direction"
    "Super+1..9              switch workspace 1..9"
    "Super+Shift+1..9        move window to workspace"
    ""
    "── window state ──"
    "Super+V                 toggle floating"
    "Super+F                 fullscreen / maximize column"
    "Super+P                 pseudo (hyprland)"
    "Super+J                 toggle split (hyprland)"
    "Super+R                 cycle preset width (niri)"
    "Super+W                 toggle tabbed column (niri)"
    ""
    "── screenshots ──"
    "Super+S                 region screenshot → satty"
    "Super+Shift+S           full / window screenshot"
    "Super+Ctrl+S            output screenshot (hyprland)"
    ""
    "── audio / brightness ──"
    "XF86 vol up/down/mute   volume control"
    "XF86 brightness up/down brightness control"
    "XF86 play/next/prev     media keys"
  ];

  binds-text = builtins.concatStringsSep "\n" binds;

  keybindHelp = pkgs.writeShellApplication {
    name = "keybind-help";
    runtimeInputs = with pkgs; [ fuzzel ];
    text = ''
      cat <<'EOF' | fuzzel --dmenu --prompt "  " --width 60 --lines 25 > /dev/null
      ${binds-text}
      EOF
    '';
  };
in
{
  home.packages = [ keybindHelp ];
}
