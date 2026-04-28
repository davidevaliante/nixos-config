{ pkgs, ... }:

let
  themes = [
    "oxocarbon-dark"
    "catppuccin-mocha"
    "tokyo-night-dark"
    "synthwave-84"
  ];

  themeSwitch = pkgs.writeShellApplication {
    name = "theme-switch";
    runtimeInputs = with pkgs; [ fuzzel libnotify systemd nixos-rebuild git ];
    text = ''
      REPO="''${THEME_SWITCH_REPO:-$HOME/nixos-config}"
      THEME_FILE="$REPO/.theme"
      HOST="$(hostname)"

      if [ "$#" -ge 1 ]; then
        choice="$1"
      else
        choice=$(printf '%s\n' ${builtins.concatStringsSep " " (map (t: "\"${t}\"") themes)} \
          | fuzzel --dmenu --prompt "theme  ")
      fi

      [ -z "$choice" ] && exit 0

      current="$(cat "$THEME_FILE" 2>/dev/null | tr -d '[:space:]')"
      if [ "$choice" = "$current" ]; then
        notify-send "Theme" "$choice is already active" -t 2000
        exit 0
      fi

      printf '%s\n' "$choice" > "$THEME_FILE"
      git -C "$REPO" add .theme 2>/dev/null || true
      notify-send "Switching theme" "Building $choice — this takes ~30s" -t 5000

      if sudo nixos-rebuild switch --flake "$REPO#$HOST" --no-update-lock-file; then
        systemctl --user restart waybar.service swaync.service 2>/dev/null || true
        notify-send "Theme switched" "Now using $choice" -t 3000
      else
        printf '%s\n' "$current" > "$THEME_FILE"
        notify-send -u critical "Theme switch failed" "Reverted to $current"
        exit 1
      fi
    '';
  };
in
{
  home.packages = [ themeSwitch ];
}
