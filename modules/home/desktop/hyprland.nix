{ pkgs, lib, config, osConfig, ... }:

let
  c = config.lib.stylix.colors;
in
{
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
        sensitivity = 0;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
      };

      general = {
        gaps_in = 6;
        gaps_out = 12;
        border_size = 2;
        layout = "dwindle";

        "col.active_border" = lib.mkForce "rgba(${c.base0D}ee) rgba(${c.base0E}ee) rgba(${c.base0C}ee) 45deg";
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
      "$browser" = "firefox";

      bind = [
        "$mod, RETURN, exec, $terminal"
        "$mod, B, exec, $browser"
        "$mod, SPACE, exec, $launcher"
        "$mod, Q, killactive,"
        "$mod SHIFT, Q, exit,"
        "$mod, V, togglefloating,"
        "$mod, F, fullscreen, 0"
        "$mod, P, pseudo,"
        "$mod, J, togglesplit,"

        "$mod, h, movefocus, l"
        "$mod, l, movefocus, r"
        "$mod, k, movefocus, u"
        "$mod, j, movefocus, d"

        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        "$mod, S, exec, hyprshot -m region -o ~/Pictures/Screenshots"
        "$mod SHIFT, S, exec, hyprshot -m window -o ~/Pictures/Screenshots"
        "$mod CTRL, S, exec, hyprshot -m output -o ~/Pictures/Screenshots"

        "$mod, escape, exec, hyprlock"
        "$mod ALT, L, exec, hyprlock"

        "$mod, N, exec, swaync-client -t -sw"
        "$mod, T, exec, theme-switch"
        "$mod SHIFT, E, exec, wlogout"
        "$mod, slash, exec, keybind-help"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      bindl = [
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

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
