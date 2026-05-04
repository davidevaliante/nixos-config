{ ... }:

{
  # Display manager moved to ./sddm.nix. xserver and the GNOME desktopManager
  # are kept on for now so a GNOME session is still selectable from SDDM as a
  # rescue option. Step 2 of the DM swap will retire this file entirely.
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;
}
