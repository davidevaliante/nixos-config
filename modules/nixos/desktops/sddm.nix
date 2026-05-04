{ pkgs, ... }:

{
  # Step 1 of the DM swap: SDDM in Wayland mode with the stock Breeze theme.
  # Stylix's `targets.sddm` (autoEnable = true) paints Breeze with the active
  # base16 palette + cursor + fonts + the gradient wallpaper, which is the
  # whole point of swapping — no per-DM theme code lives here.
  #
  # Things deliberately NOT changed in this step (each is a separate, later
  # rebuild so failures stay diagnosable):
  #   - services.xserver.enable / services.desktopManager.gnome.enable
  #     remain on; GNOME stays installed as a fallback session.
  #   - No custom QML theme, no themeConfig override, no astronaut.
  #
  # Rescue path if the greeter doesn't appear: Ctrl+Alt+F2 → TTY → log in →
  # `sudo nixos-rebuild switch --rollback`. Confirm TTY login *before* the
  # first rebuild that switches DMs.
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;  # Qt6 SDDM, required by modern stylix theming
  };
}
