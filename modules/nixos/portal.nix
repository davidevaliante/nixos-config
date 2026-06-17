{ pkgs, ... }:

{
  # home-manager sets NIX_XDG_DESKTOP_PORTAL_DIR to its per-user profile, which
  # only contains hyprland.portal — under niri that leaves the ScreenCast
  # interface unresolved and OBS/Google Meet show "no capture sources". Point it
  # at the system profile, which carries the full set
  # (gnome/gtk/hyprland/gnome-keyring).
  #
  # NOTE: this NixOS-level value is SHADOWED by home-manager's session vars at
  # login (the HM Hyprland module re-exports the var to the per-user profile), so
  # the *effective* override lives in modules/home/desktop/hyprland.nix via
  # `home.sessionVariables ... lib.mkForce`. This is kept as a fallback for
  # root/non-HM shells.
  environment.sessionVariables.NIX_XDG_DESKTOP_PORTAL_DIR =
    "/run/current-system/sw/share/xdg-desktop-portal/portals";

  # `config.common.default = "*"` is the lazy default but it makes xdg-desktop-portal
  # probe every registered backend on every call, with dbus timeouts piling up — that
  # showed up as ~10s GTK app launches on this host. Pin a deterministic priority
  # order per-DE instead. `niri` and `hyprland` matchers key on $XDG_CURRENT_DESKTOP.
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome   # screencast/screenshot under niri
    ];
    config = {
      common.default = [ "gtk" ];

      niri = {
        default = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };

      hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.Screencast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
      };
    };
  };
}
