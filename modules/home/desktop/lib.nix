{ config, ... }:

let
  isNoctalia = config.mySystem.desktop.shell == "noctalia";

  # Canonical commands for shell-level actions, as argv lists.
  # Niri's `spawn` accepts the list directly; Hyprland's `extraConfig` needs
  # the string form (`cmdsStr`). Keep both branches in lockstep here so a
  # change to the noctalia IPC or the traditional fallback updates both
  # compositors at once.
  cmds = {
    # noctalia 5.x renamed the binary (`noctalia-shell` → `noctalia`) and
    # replaced the `ipc call <target> <action>` IPC with `msg <command>`
    # (run `noctalia msg --help` for the catalogue). Panels toggle by id
    # (`panel-toggle <id>`); notification history is the control-center
    # `notifications` tab; the keybind-cheatsheet plugin is gone (QML plugins
    # don't load in v5) so that binding falls back to the local keybind-help.
    launcher     = if isNoctalia then [ "noctalia" "msg" "panel-toggle" "launcher" ]                       else [ "fuzzel" ];
    notify       = if isNoctalia then [ "noctalia" "msg" "panel-toggle" "control-center" "notifications" ] else [ "swaync-client" "-t" "-sw" ];
    lock         = if isNoctalia then [ "noctalia" "msg" "session" "lock" ]                                else [ "hyprlock" ];
    session      = if isNoctalia then [ "noctalia" "msg" "panel-toggle" "session" ]                        else [ "wlogout" ];
    cheatsheet   = [ "keybind-help" ];
    windowSwitch = if isNoctalia then [ "noctalia" "msg" "window-switcher" "open" ]                        else [ "niri-window-switcher" ];
    clipboard    = if isNoctalia then [ "noctalia" "msg" "panel-toggle" "clipboard" ]                      else [ "clipboard-picker" ];
  };

  cmdsStr = builtins.mapAttrs (_: builtins.concatStringsSep " ") cmds;
in
{
  _module.args.desktopLib = { inherit isNoctalia cmds cmdsStr; };
}
