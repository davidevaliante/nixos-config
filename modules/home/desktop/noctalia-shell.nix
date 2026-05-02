{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.mySystem.desktop;
  active = cfg.shell == "noctalia";

  # The keybind-cheatsheet plugin parses the niri/hyprland config once and
  # caches the result in its plugin settings.json forever — new binds added
  # later don't appear until that cache is cleared and the shell restarts.
  # `noctalia-reload` does both, and `home.activation` wipes the cache on
  # every HM rebuild so the next shell start always re-parses.
  cheatsheetCache = "$HOME/.config/noctalia/plugins/keybind-cheatsheet/settings.json";

  noctaliaReload = pkgs.writeShellScriptBin "noctalia-reload" ''
    set -eu
    pid=$(${pkgs.procps}/bin/pgrep -x quickshell || true)
    if [ -n "$pid" ]; then
      kill "$pid" || true
      for _ in 1 2 3 4 5; do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.2
      done
    fi
    if [ -f "${cheatsheetCache}" ]; then
      ${pkgs.jq}/bin/jq '.cheatsheetData = [] | .detectedCompositor = ""' \
        "${cheatsheetCache}" > "${cheatsheetCache}.tmp" \
        && mv "${cheatsheetCache}.tmp" "${cheatsheetCache}"
    fi
    setsid noctalia-shell </dev/null >/dev/null 2>&1 &
  '';
in
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell = lib.mkIf active {
    enable = true;

    settings = {
      # `useSeparateOpacity` decouples the bar's opacity from
      # `ui.panelBackgroundOpacity` (which stylix forces to 1.0 to keep
      # popups readable). Without this flag, `bar.backgroundOpacity` is
      # silently ignored and the bar inherits the panel opacity.
      bar.useSeparateOpacity = lib.mkForce true;
      bar.backgroundOpacity = lib.mkForce 0.0;
      # VPN isn't in the default right-widget list; adding it surfaces the
      # NetworkManager VPN toggle next to Tray/NotificationHistory.
      bar.widgets.right = lib.mkForce [
        { id = "Tray"; }
        { id = "NotificationHistory"; }
        {
          id = "VPN";
          displayMode = "alwaysShow"; # always show the pill, not just on hover
          iconColor = "tertiary";     # purple in Oxocarbon
          textColor = "tertiary";
        }
        { id = "Battery"; }
        { id = "Volume"; }
        { id = "Bluetooth"; }
        { id = "Brightness"; }
        { id = "ControlCenter"; }
      ];
      ui.fontDefault = lib.mkForce "0xProto Nerd Font";
      colorSchemes = {
        useWallpaperColors = false;
        predefinedScheme = "Oxocarbon";
      };
    };

    plugins = {
      version = 2;
      sources = [
        {
          enabled = true;
          name = "Noctalia Plugins";
          url = "https://github.com/noctalia-dev/noctalia-plugins";
        }
      ];
      states = {
        keybind-cheatsheet = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        screen-toolkit = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
      };
    };
  };

  # Ship plugins straight from the noctalia-plugins flake input
  # (single-source-of-truth for plugin code), plus the custom Oxocarbon
  # colorscheme (noctalia scans this dir with `find -L`, so symlinks work).
  # `recursive = true` keeps the plugin directory a real, writable folder
  # (each file inside is its own symlink) so noctalia can persist per-plugin
  # settings.json. With a single dir-level symlink to the read-only store,
  # plugins like keybind-cheatsheet hang on "loading" because their cache
  # write fails.
  xdg.configFile."noctalia/plugins/keybind-cheatsheet" = lib.mkIf active {
    source = "${inputs.noctalia-plugins}/keybind-cheatsheet";
    recursive = true;
  };

  xdg.configFile."noctalia/plugins/screen-toolkit" = lib.mkIf active {
    source = "${inputs.noctalia-plugins}/screen-toolkit";
    recursive = true;
  };

  xdg.configFile."noctalia/colorschemes/Oxocarbon/Oxocarbon.json" = lib.mkIf active {
    source = ./noctalia/colorschemes/Oxocarbon.json;
  };

  home.packages = lib.mkIf active [ noctaliaReload ];

  # Wipe the keybind-cheatsheet cache on every rebuild. The plugin only
  # re-parses when this is empty, so this guarantees the next noctalia
  # start (whether via `noctalia-reload`, logout, or reboot) picks up new
  # binds. While noctalia is running it keeps stale data in memory — run
  # `noctalia-reload` to refresh immediately.
  home.activation.noctaliaCheatsheetCacheReset = lib.mkIf active (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f "${cheatsheetCache}" ]; then
        ${pkgs.jq}/bin/jq '.cheatsheetData = [] | .detectedCompositor = ""' \
          "${cheatsheetCache}" > "${cheatsheetCache}.tmp" \
          && mv "${cheatsheetCache}.tmp" "${cheatsheetCache}"
      fi
    ''
  );

  # Noctalia's home module no longer manages a systemd unit (deprecated upstream),
  # so the shell must be launched from each compositor's autostart.
  wayland.windowManager.hyprland.settings.exec-once =
    lib.mkIf active [ "noctalia-shell" ];

  programs.niri.settings.spawn-at-startup =
    lib.mkIf active [ { command = [ "noctalia-shell" ]; } ];
}
