{ lib, ... }:

{
  options.mySystem.desktop.shell = lib.mkOption {
    type = lib.types.enum [ "traditional" "noctalia" ];
    default = "traditional";
    description = ''
      Which desktop shell stack to load.

      - "traditional": waybar + swaync + fuzzel (current handcrafted setup,
        styled from the active stylix base16 palette).
      - "noctalia": noctalia-shell, a Quickshell-based unified shell that
        replaces bar + notifications + launcher + lock + idle + OSD + dock.

      Switching is a one-line change in home/davide/default.nix; the modules
      for the inactive option are skipped entirely (no leftover services).
    '';
  };
}
