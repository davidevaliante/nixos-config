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
        # RO's client is 32-bit; wineWow provides both 32- and 64-bit wine.
        pkgs.wineWowPackages.stable
        pkgs.winetricks
      ];
    })
  ];
}
