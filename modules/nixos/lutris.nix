{ pkgs, ... }:

{
  # Lutris manages the Wine prefix + community installer for uaRO (and other
  # non-Steam games). nixpkgs wraps lutris in an FHS env, so overriding
  # `extraPkgs` is the reliable way to get Wine onto its runners — Lutris's
  # own auto-downloaded wine-ge builds are flaky on NixOS, and it ships no
  # winetricks. 32-bit graphics + Proton-GE already come from the graphics
  # and steam modules; nothing here duplicates them.
  environment.systemPackages = [
    (pkgs.lutris.override {
      extraPkgs = pkgs: [
        # RO's client is 32-bit. wineWow64 is Wine's "new WoW64": a 64-bit
        # build that runs 32-bit Windows apps without a separate 32-bit host
        # build. Upstream deprecated the old multilib wineWowPackages in its
        # favor. If uaRO ever misbehaves under new-WoW64, fall back to
        # Lutris's own downloaded wine-ge runner per game.
        pkgs.wineWow64Packages.stable
        pkgs.winetricks
      ];
    })
  ];
}
