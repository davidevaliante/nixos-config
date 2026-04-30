{ pkgs, ... }:

let
  windowSwitcher = pkgs.writeShellApplication {
    name = "niri-window-switcher";
    runtimeInputs = with pkgs; [ niri jq fuzzel ];
    text = ''
      sel=$(niri msg --json windows \
        | jq -r '.[] | "\(.id) │ \(.app_id // "?") — \(.title // "untitled") (ws \(.workspace_id // "?"))"' \
        | fuzzel --dmenu --prompt "window  ")
      [ -z "$sel" ] && exit 0
      id=$(printf '%s' "$sel" | awk '{print $1}')
      niri msg action focus-window --id "$id"
    '';
  };
in
{
  home.packages = [ windowSwitcher ];
}
