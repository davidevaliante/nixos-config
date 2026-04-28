{ config, lib, inputs, ... }:

let
  cfg = config.mySystem.desktop;
  active = cfg.shell == "noctalia";
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = active;
  };

  # Noctalia's home module no longer manages a systemd unit (deprecated upstream),
  # so the shell must be launched from each compositor's autostart.
  wayland.windowManager.hyprland.settings.exec-once =
    lib.mkIf active [ "noctalia-shell" ];

  programs.niri.settings.spawn-at-startup =
    lib.mkIf active [ { command = [ "noctalia-shell" ]; } ];
}
