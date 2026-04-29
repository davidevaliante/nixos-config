{ config, lib, inputs, ... }:

let
  cfg = config.mySystem.desktop;
  active = cfg.shell == "noctalia";
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

  # Noctalia's home module no longer manages a systemd unit (deprecated upstream),
  # so the shell must be launched from each compositor's autostart.
  wayland.windowManager.hyprland.settings.exec-once =
    lib.mkIf active [ "noctalia-shell" ];

  programs.niri.settings.spawn-at-startup =
    lib.mkIf active [ { command = [ "noctalia-shell" ]; } ];
}
