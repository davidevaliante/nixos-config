{ config, ... }:

let
  isNoctalia = config.mySystem.desktop.shell == "noctalia";

  # Canonical commands for shell-level actions, as argv lists.
  # Niri's `spawn` accepts the list directly; Hyprland's `extraConfig` needs
  # the string form (`cmdsStr`). Keep both branches in lockstep here so a
  # change to the noctalia IPC or the traditional fallback updates both
  # compositors at once.
  cmds = {
    launcher     = if isNoctalia then [ "noctalia-shell" "ipc" "call" "launcher" "toggle" ]                         else [ "fuzzel" ];
    notify       = if isNoctalia then [ "noctalia-shell" "ipc" "call" "notifications" "toggleHistory" ]             else [ "swaync-client" "-t" "-sw" ];
    lock         = if isNoctalia then [ "noctalia-shell" "ipc" "call" "lockScreen" "lock" ]                         else [ "hyprlock" ];
    session      = if isNoctalia then [ "noctalia-shell" "ipc" "call" "sessionMenu" "toggle" ]                      else [ "wlogout" ];
    cheatsheet   = if isNoctalia then [ "noctalia-shell" "ipc" "call" "plugin" "togglePanel" "keybind-cheatsheet" ] else [ "keybind-help" ];
    windowSwitch = if isNoctalia then [ "noctalia-shell" "ipc" "call" "launcher" "windows" ]                        else [ "niri-window-switcher" ];
    clipboard    = if isNoctalia then [ "noctalia-shell" "ipc" "call" "plugin:clipper" "toggle" ]                   else [ "clipboard-picker" ];
  };

  cmdsStr = builtins.mapAttrs (_: builtins.concatStringsSep " ") cmds;
in
{
  _module.args.desktopLib = { inherit isNoctalia cmds cmdsStr; };
}
