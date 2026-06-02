{ inputs, pkgs, ... }:

{
  imports = [ inputs.niri.nixosModules.niri ];

  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  programs.niri = {
    enable = true;
    package = pkgs.niri-stable;
  };

  # niri >=25.08 auto-spawns xwayland-satellite on demand and exports DISPLAY,
  # but only if the binary is on PATH. Without it, X11 clients (Steam, any
  # 32-bit game, older Electron apps) silently fail with "check your DISPLAY".
  environment.systemPackages = [ pkgs.xwayland-satellite ];
}
