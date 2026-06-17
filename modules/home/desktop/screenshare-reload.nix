{ pkgs, ... }:

let
  portalDir = "/run/current-system/sw/share/xdg-desktop-portal/portals";

  # `screenshare-reload` recovers Wayland screen-sharing without a full relogin.
  # The usual failure: after long uptime the PipeWire/portal stack wedges, or the
  # ScreenCast D-Bus interface goes missing (e.g. a stale NIX_XDG_DESKTOP_PORTAL_DIR
  # pointing at a portals dir without the gnome backend). This re-pins the portal
  # dir in the systemd user env, bounces the media + portal services, and verifies
  # the ScreenCast interface came back. Restart the browser afterwards — Chrome
  # caches portal availability at launch.
  screenshare-reload = pkgs.writeShellScriptBin "screenshare-reload" ''
    set -u
    sc() { ${pkgs.systemd}/bin/systemctl --user "$@"; }

    echo ":: pinning portal dir -> ${portalDir}"
    sc set-environment NIX_XDG_DESKTOP_PORTAL_DIR="${portalDir}"

    echo ":: restarting media stack"
    sc restart pipewire.service wireplumber.service pipewire-pulse.service

    echo ":: restarting portal frontend + backends"
    # stop backends so they re-activate fresh against the new frontend
    sc stop xdg-desktop-portal-gnome.service xdg-desktop-portal-gtk.service \
            xdg-desktop-portal-hyprland.service 2>/dev/null || true
    sc restart xdg-desktop-portal.service

    sleep 2
    echo ":: verifying ScreenCast interface"
    if ${pkgs.systemd}/bin/busctl --user introspect \
         org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop 2>/dev/null \
         | grep -q 'org.freedesktop.portal.ScreenCast'; then
      echo "OK: ScreenCast is available. Restart your browser, then retry sharing."
    else
      echo "FAIL: ScreenCast still missing. Check 'journalctl --user -u xdg-desktop-portal'."
      exit 1
    fi
  '';
in
{
  home.packages = [ screenshare-reload ];
}
