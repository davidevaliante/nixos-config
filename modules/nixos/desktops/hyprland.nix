{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Hyprland-specific portal backend; the cross-DE portal config lives in
  # ../portal.nix.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  security.polkit.enable = true;

  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    hyprpolkitagent
  ];
}
