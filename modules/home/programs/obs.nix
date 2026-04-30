{ pkgs, ... }:

{
  # Wayland screencapture works via PipeWire + xdg-desktop-portal, which
  # is already wired up at the NixOS level (xdg.portal.enable + the
  # compositor-specific portal). OBS picks the PipeWire source up
  # automatically — no Wayland-specific plugin needed for modern OBS.
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture # capture audio of individual apps via PipeWire
    ];
  };
}
