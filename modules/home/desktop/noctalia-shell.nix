{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.mySystem.desktop;
  active = cfg.shell == "noctalia";

  # The keybind-cheatsheet plugin parses the niri/hyprland config once and
  # caches the result in its plugin settings.json forever — new binds added
  # later don't appear until that cache is cleared and the shell restarts.
  # `noctalia-reload` does both, and `home.activation` wipes the cache on
  # every HM rebuild so the next shell start always re-parses.
  cheatsheetCache = "$HOME/.config/noctalia/plugins/keybind-cheatsheet/settings.json";

  # Qt persists compiled QML bytecode here, keyed by file path. Plugins
  # symlinked from /nix/store change content on every rebuild but keep the
  # same ~/.config path — so Qt happily serves stale bytecode and ignores
  # property changes (e.g. an updated `icon:` string renders as the
  # default-fallback skull). Wipe the cache on every reload and rebuild so
  # the new sources actually take effect.
  qmlCacheDir = "$HOME/.cache/noctalia-qs/qmlcache";

  # Region screenshot → Litterbox (1h temp host) → Google Lens by URL.
  # Lens has no public unauthenticated upload endpoint that's stable from a
  # shell client, so we round-trip through a temp host the same way
  # Snipping-Lens/QuickSnip do.
  lensSearch = pkgs.writeShellScriptBin "lens-search" ''
    set -eu
    img=$(${pkgs.coreutils}/bin/mktemp --suffix=.png)
    trap 'rm -f "$img"' EXIT
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" "$img"
    url=$(${pkgs.curl}/bin/curl -fsS \
      -F "reqtype=fileupload" \
      -F "time=1h" \
      -F "fileToUpload=@$img" \
      https://litterbox.catbox.moe/resources/internals/api.php) || url=""
    if [ -z "$url" ] || [ "''${url#http}" = "$url" ]; then
      ${pkgs.libnotify}/bin/notify-send -u critical "Lens search failed" "Upload to Litterbox failed"
      exit 1
    fi
    ${pkgs.xdg-utils}/bin/xdg-open "https://lens.google.com/uploadbyurl?url=$url"
  '';

  # hyprpicker -a copies the hex to the Wayland clipboard and prints it.
  # We surface the value as a notification so the user knows the pick landed.
  colorPick = pkgs.writeShellScriptBin "color-pick" ''
    set -eu
    color=$(${pkgs.hyprpicker}/bin/hyprpicker -a -f hex || true)
    if [ -n "''${color:-}" ]; then
      ${pkgs.libnotify}/bin/notify-send "Color picked" "$color"
    fi
  '';

  noctaliaReload = pkgs.writeShellScriptBin "noctalia-reload" ''
    set -eu
    # The nix wrapper renames the process to `.quickshell-wra`, so we match
    # by full command line against the bin path instead of process name.
    pid=$(${pkgs.procps}/bin/pgrep -f '/bin/quickshell$' || true)
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
    rm -rf "${qmlCacheDir}"
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
        { id = "plugin:lens-search"; }
        { id = "plugin:color-picker"; }
        {
          id = "VPN";
          displayMode = "alwaysShow"; # always show the pill, not just on hover
          iconColor = "tertiary"; # purple in Oxocarbon
          textColor = "tertiary";
        }
        { id = "Battery"; }
        { id = "Volume"; }
        { id = "Bluetooth"; }
        { id = "Brightness"; }
        { id = "ControlCenter"; }
      ];
      notifications = {
        location = "bottom_right";
        density = "compact";
        lowUrgencyDuration = 2;
        normalUrgencyDuration = 5;
        criticalUrgencyDuration = 10;
      };
      ui.fontDefault = lib.mkForce "0xProto Nerd Font";
      colorSchemes = {
        useWallpaperColors = false;
        predefinedScheme = "Oxocarbon";
      };

      # Idle pipeline: DPMS off → lock → suspend. Timeouts are absolute (each
      # measured from the last input event), not additive — so lock fires 30
      # min after idle started, not 30 min after the screen turned off.
      idle = {
        enabled = true;
        screenOffTimeout = 15 * 60;
        lockTimeout = 30 * 60;
        suspendTimeout = 2 * 60 * 60;
      };

      # Override the session menu's logout action.
      #
      # Noctalia's default logout calls `loginctl terminate-session`, which kills
      # the systemd user scope but leaves niri/Hyprland running detached — the
      # compositor never tells the DM to reclaim the display, so GDM hangs and
      # only a hard reboot recovers. The fix per niri/discussions/{2729,3038} is
      # to ask the compositor to quit itself first; logind cleanup follows
      # cleanly. We pin the full powerOptions array (entries with empty
      # `command` fall through to noctalia's defaults) so the menu still shows
      # every option — overriding only `logout`.
      sessionMenu.powerOptions = lib.mkForce [
        {
          action = "lock";
          enabled = true;
          countdownEnabled = true;
          command = "";
          keybind = "";
        }
        {
          action = "suspend";
          enabled = true;
          countdownEnabled = true;
          command = "";
          keybind = "";
        }
        {
          action = "hibernate";
          enabled = true;
          countdownEnabled = true;
          command = "";
          keybind = "";
        }
        {
          action = "reboot";
          enabled = true;
          countdownEnabled = true;
          command = "";
          keybind = "";
        }
        {
          action = "userspaceReboot";
          enabled = false;
          countdownEnabled = true;
          command = "";
          keybind = "";
        }
        {
          action = "rebootToUefi";
          enabled = true;
          countdownEnabled = true;
          command = "";
          keybind = "";
        }
        {
          action = "logout";
          enabled = true;
          countdownEnabled = true;
          command = "case $XDG_CURRENT_DESKTOP in niri) niri msg action quit -s ;; Hyprland) hyprctl dispatch exit ;; esac";
          keybind = "";
        }
        {
          action = "shutdown";
          enabled = true;
          countdownEnabled = true;
          command = "";
          keybind = "";
        }
      ];
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
        lens-search = {
          enabled = true;
          sourceUrl = "local";
        };
        color-picker = {
          enabled = true;
          sourceUrl = "local";
        };
        clipper = {
          enabled = true;
          sourceUrl = "https://github.com/blackbartblues/noctalia-clipper";
        };
      };
    };
  };

  # Ship plugins from three sources: the upstream noctalia-plugins flake
  # input (keybind-cheatsheet), the third-party clipper input, and locally
  # authored plugins under ./noctalia/plugins (lens-search, color-picker).
  # `recursive = true` keeps the plugin directory a real, writable folder
  # (each file inside is its own symlink) so noctalia can persist per-plugin
  # settings.json. With a single dir-level symlink to the read-only store,
  # plugins like keybind-cheatsheet hang on "loading" because their cache
  # write fails.
  xdg.configFile."noctalia/plugins/keybind-cheatsheet" = lib.mkIf active {
    source = "${inputs.noctalia-plugins}/keybind-cheatsheet";
    recursive = true;
  };

  xdg.configFile."noctalia/plugins/lens-search" = lib.mkIf active {
    source = ./noctalia/plugins/lens-search;
    recursive = true;
  };

  xdg.configFile."noctalia/plugins/color-picker" = lib.mkIf active {
    source = ./noctalia/plugins/color-picker;
    recursive = true;
  };

  xdg.configFile."noctalia/plugins/clipper" = lib.mkIf active {
    source = inputs.noctalia-clipper.outPath;
    recursive = true;
  };

  xdg.configFile."noctalia/colorschemes/Oxocarbon/Oxocarbon.json" = lib.mkIf active {
    source = ./noctalia/colorschemes/Oxocarbon.json;
  };

  home.packages = lib.mkIf active [
    noctaliaReload
    lensSearch
    colorPick
    pkgs.hyprpicker
  ];

  # Surface the helper scripts in fuzzel (and any other XDG launcher) so the
  # user can invoke them without a dedicated keybind. NoDisplay=false so they
  # show up in the launcher; Terminal=false so they don't pop a kitty window.
  xdg.desktopEntries = lib.mkIf active {
    lens-search = {
      name = "Lens Search";
      comment = "Region screenshot → Google Lens";
      exec = "lens-search";
      icon = "search";
      terminal = false;
      categories = [ "Utility" "Graphics" ];
    };
    color-pick = {
      name = "Color Picker";
      comment = "Pick a pixel color from the screen";
      exec = "color-pick";
      icon = "color-picker";
      terminal = false;
      categories = [ "Utility" "Graphics" ];
    };
  };

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
      rm -rf "${qmlCacheDir}"
    ''
  );

  # Noctalia's home module no longer manages a systemd unit (deprecated upstream),
  # so the shell must be launched from each compositor's autostart.
  wayland.windowManager.hyprland.settings.exec-once = lib.mkIf active [ "noctalia-shell" ];

  programs.niri.settings.spawn-at-startup = lib.mkIf active [ { command = [ "noctalia-shell" ]; } ];
}
