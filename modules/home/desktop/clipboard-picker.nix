{ pkgs, ... }:

let
  # Traditional-shell clipboard picker. The noctalia-clipper plugin is the
  # primary UI when noctalia is active; this is the fallback for the fuzzel
  # stack. Both backends share the same `cliphist` store, so history is
  # preserved across shell switches.
  clipboardPicker = pkgs.writeShellApplication {
    name = "clipboard-picker";
    runtimeInputs = with pkgs; [ cliphist fuzzel wl-clipboard ];
    text = ''
      sel=$(cliphist list | fuzzel --dmenu --prompt "  " --width 80) || exit 0
      [ -z "$sel" ] && exit 0
      printf '%s' "$sel" | cliphist decode | wl-copy
    '';
  };

  clipboardClear = pkgs.writeShellApplication {
    name = "clipboard-clear";
    runtimeInputs = with pkgs; [ cliphist ];
    text = "cliphist wipe";
  };
in
{
  home.packages = [ clipboardPicker clipboardClear ];
}
