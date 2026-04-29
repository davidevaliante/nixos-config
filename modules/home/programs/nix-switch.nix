{ pkgs, ... }:

let
  # `nixos-rebuild` is intentionally NOT in runtimeInputs and is invoked via
  # the stable `/run/current-system/sw/bin/...` path. runtimeInputs would
  # prepend a versioned `/nix/store/...-nixos-rebuild-ng-XX/bin` to PATH;
  # sudo then resolves the command to that store path and the NOPASSWD rule
  # (which matches /run/current-system/sw/bin/nixos-rebuild) silently misses,
  # so every rebuild prompts for a password.
  nixSwitch = pkgs.writeShellApplication {
    name = "nix-switch";
    runtimeInputs = with pkgs; [ nix ];
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
      sudo /run/current-system/sw/bin/nixos-rebuild "$MODE" --flake "$REPO#$HOST" --no-update-lock-file
    '';
  };
in
{
  home.packages = [ nixSwitch ];
}
