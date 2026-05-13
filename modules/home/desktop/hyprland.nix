{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:

let
  c = config.lib.stylix.colors;
  host = osConfig.networking.hostName;
  mouseSensitivity = if host == "helium" then -0.1 else 0;
in
{
  imports = [ ./hyprland-keybinds.nix ];

  stylix.targets.hyprpaper.enable = lib.mkForce false;
  services.hyprpaper.enable = lib.mkForce false;

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    settings = {
      monitor = [ ",preferred,auto,1" ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = mouseSensitivity;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
      };

      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 3;
        layout = "dwindle";

        "col.active_border" =
          lib.mkForce "rgba(${c.base0D}ee) rgba(${c.base0E}ee) rgba(${c.base0C}ee) 45deg";
        "col.inactive_border" = lib.mkForce "rgba(${c.base02}aa)";
      };

      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
          new_optimizations = true;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "myBezier, 0.05, 0.9, 0.1, 1.05"
          "linear, 0, 0, 1, 1"
        ];
        animation = [
          "windows, 1, 5, myBezier"
          "windowsOut, 1, 5, default, popin 80%"
          "border, 1, 5, default"
          "borderangle, 1, 60, linear, loop"
          "fade, 1, 5, default"
          "workspaces, 1, 4, default"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
      };

      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$launcher" = "fuzzel";
      "$browser" = "google-chrome-stable";

      exec-once = [
        "${pkgs.awww}/bin/awww-daemon"
        "sleep 1 && ${pkgs.awww}/bin/awww img ${osConfig.stylix.image}"
        "systemctl --user start hyprpolkitagent"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];
    };
  };

  home.packages = with pkgs; [
    awww
    hyprshot
    grim
    slurp
    satty
    swappy
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
  ];

  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland Polkit Agent";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
    };
  };
}
