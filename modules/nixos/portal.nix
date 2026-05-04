{ pkgs, ... }:

{
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
