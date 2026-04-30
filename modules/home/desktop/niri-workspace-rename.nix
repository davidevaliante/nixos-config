{ pkgs, ... }:

let
  workspaceRename = pkgs.writeShellApplication {
    name = "niri-workspace-rename";
    runtimeInputs = with pkgs; [ niri fuzzel ];
    text = ''
      result=$(printf '<unset>\n' | fuzzel --dmenu --prompt "ws  " --placeholder "name") || exit 0
      case "$result" in
        '<unset>') niri msg action unset-workspace-name ;;
        ""       ) exit 0 ;;
        *        ) niri msg action set-workspace-name "$result" ;;
      esac
    '';
  };
in
{
  home.packages = [ workspaceRename ];
}
