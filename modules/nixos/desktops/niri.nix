{ inputs, pkgs, ... }:

{
  imports = [ inputs.niri.nixosModules.niri ];

  nixpkgs.overlays = [
    # niri-flake (stale since 2026-08) hard-asserts `libdisplay-info_0_2.version
    # == "0.2.0"`, but current nixpkgs removed that package (it's now a
    # throw-on-eval alias; nixpkgs ships 0.3.0 as _0_3 and 0.4.0 as the default).
    # niri-flake's own pinned `nixpkgs-stable` still carries a real 0.2.0, so we
    # resurrect it from there. Must come before the niri overlay so niri-stable's
    # callPackage resolves the real package. Drop this once niri-flake moves to
    # libdisplay-info 0.3/0.4.
    (final: prev: {
      libdisplay-info_0_2 =
        (import inputs.niri.inputs.nixpkgs-stable {
          inherit (prev.stdenv.hostPlatform) system;
        }).libdisplay-info_0_2;
    })
    inputs.niri.overlays.niri
  ];

  programs.niri = {
    enable = true;
    package = pkgs.niri-stable;
  };

  # niri >=25.08 auto-spawns xwayland-satellite on demand and exports DISPLAY,
  # but only if the binary is on PATH. Without it, X11 clients (Steam, any
  # 32-bit game, older Electron apps) silently fail with "check your DISPLAY".
  environment.systemPackages = [ pkgs.xwayland-satellite ];
}
