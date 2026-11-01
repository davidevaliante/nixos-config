{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # The Hyprland portal backend (xdg-desktop-portal-hyprland) is wired
  # automatically by `programs.hyprland.enable` — it appends `cfg.portalPackage`
  # to `xdg.portal.extraPortals`. Listing it again here double-registers the
  # portal's systemd *user* unit, which collides ("File exists") in the
  # user-units build. The cross-DE portal config lives in ../portal.nix.

  security.polkit.enable = true;

  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
  ];
}
