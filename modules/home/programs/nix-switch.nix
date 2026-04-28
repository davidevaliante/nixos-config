{ pkgs, ... }:

let
  nixSwitch = pkgs.writeShellApplication {
    name = "nix-switch";
    runtimeInputs = with pkgs; [ nixos-rebuild git nix ];
    text = ''
      REPO="''${NIX_SWITCH_REPO:-$HOME/nixos-config}"
      HOST="$(cat /etc/hostname | tr -d '[:space:]')"
      MODE="switch"
      DO_UPDATE=0

      for arg in "$@"; do
        case "$arg" in
          update|-u|--update) DO_UPDATE=1 ;;
          boot)               MODE="boot" ;;
          test)               MODE="test" ;;
          dry|dry-run)        MODE="dry-build" ;;
          -h|--help)
            cat <<EOF
nix-switch [update] [switch|boot|test|dry]
  update      run 'nix flake update' first
  switch      activate now AND set as default boot (default)
  boot        activate on next boot, don't switch now
  test        activate now, don't set as default boot
  dry         evaluate + show what would change, don't build
EOF
            exit 0 ;;
        esac
      done

      cd "$REPO"

      if [ "$DO_UPDATE" = 1 ]; then
        echo ">>> nix flake update"
        nix flake update
      fi

      echo ">>> nixos-rebuild $MODE  (host=$HOST)"
      sudo nixos-rebuild "$MODE" --flake "$REPO#$HOST" --no-update-lock-file
    '';
  };
in
{
  home.packages = [ nixSwitch ];
}
