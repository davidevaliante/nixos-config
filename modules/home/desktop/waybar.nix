{ config, lib, ... }:

let
  c = config.lib.stylix.colors.withHashtag;
in
{
  stylix.targets.waybar.enable = lib.mkForce false;

  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 38;
      spacing = 0;
      margin-top = 6;
      margin-left = 10;
      margin-right = 10;

      modules-left = [ "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "tray" "pulseaudio" "network" "battery" "custom/notification" ];

      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          default = "";
        };
        on-click = "activate";
      };

      "hyprland/window" = {
        format = "{title}";
        max-length = 80;
        separate-outputs = true;
      };

      clock = {
        format = "{:%H:%M}";
        format-alt = "{:%A, %B %d, %Y (%R)}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        calendar = {
          mode = "year";
          mode-mon-col = 3;
          weeks-pos = "right";
          on-scroll = 1;
          format = {
            months = "<span color='#${c.base0E}'><b>{}</b></span>";
            days = "<span color='#${c.base05}'>{}</span>";
            weeks = "<span color='#${c.base0C}'><b>W{}</b></span>";
            weekdays = "<span color='#${c.base0A}'><b>{}</b></span>";
            today = "<span color='#${c.base08}'><b><u>{}</u></b></span>";
          };
        };
        actions = {
          on-click-right = "mode";
          on-scroll-up = "shift_up";
          on-scroll-down = "shift_down";
        };
        on-click = "gnome-calendar";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = " muted";
        format-icons.default = [ "" "" "" ];
        on-click = "pwvucontrol";
        on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        scroll-step = 5;
      };

      network = {
        format-wifi = " {essid}";
        format-ethernet = " {ipaddr}";
        format-disconnected = " disc.";
        tooltip-format-wifi = "{essid} ({signalStrength}%)\n{ifname}: {ipaddr}";
        tooltip-format-ethernet = "{ifname}: {ipaddr}";
        on-click = "wifi-picker";
        on-click-right = "nm-connection-editor";
      };

      battery = {
        format = "{icon} {capacity}%";
        format-charging = " {capacity}%";
        format-icons = [ "" "" "" "" "" ];
        states = {
          warning = 30;
          critical = 15;
        };
        tooltip-format = "{timeTo} ({power}W)";
      };

      tray = {
        spacing = 8;
      };

      "custom/notification" = {
        tooltip-format = "{} notifications";
        format = "{icon}";
        format-icons = {
          notification = "";
          none = "";
          dnd-notification = "";
          dnd-none = "";
          inhibited-notification = "";
          inhibited-none = "";
          dnd-inhibited-notification = "";
          dnd-inhibited-none = "";
        };
        return-type = "json";
        exec-if = "which swaync-client";
        exec = "swaync-client -swb";
        on-click = "swaync-client -t -sw";
        on-click-right = "swaync-client -d -sw";
      };
    };

    style = ''
      * {
        font-family: "Inter", "JetBrainsMono Nerd Font";
        font-size: 13px;
        font-weight: 500;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
        color: ${c.base05};
      }

      #workspaces,
      #window,
      #clock,
      #pulseaudio,
      #network,
      #battery,
      #tray,
      #custom-notification {
        background: alpha(${c.base01}, 0.85);
        border: 1px solid alpha(${c.base02}, 0.6);
        border-radius: 12px;
        padding: 0 12px;
        margin: 4px 3px;
      }

      #workspaces {
        padding: 2px 4px;
      }

      #workspaces button {
        padding: 0 9px;
        margin: 2px 2px;
        color: ${c.base04};
        background: transparent;
        border-radius: 8px;
        transition: all 200ms ease;
      }

      #workspaces button:hover {
        background: alpha(${c.base02}, 0.6);
        color: ${c.base05};
      }

      #workspaces button.active {
        color: ${c.base00};
        background: ${c.base0D};
        font-weight: 700;
      }

      #workspaces button.urgent {
        color: ${c.base00};
        background: ${c.base08};
      }

      #window {
        color: ${c.base04};
        font-style: italic;
      }

      #clock {
        color: ${c.base0E};
        font-weight: 600;
      }

      #pulseaudio {
        color: ${c.base0C};
      }

      #pulseaudio.muted {
        color: ${c.base03};
      }

      #network {
        color: ${c.base0B};
      }

      #network.disconnected {
        color: ${c.base08};
      }

      #battery {
        color: ${c.base0A};
      }

      #battery.charging {
        color: ${c.base0B};
      }

      #battery.warning:not(.charging) {
        color: ${c.base09};
      }

      #battery.critical:not(.charging) {
        color: ${c.base08};
        animation: blink 1s steps(2) infinite;
      }

      @keyframes blink {
        50% { color: ${c.base05}; }
      }

      #custom-notification {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 15px;
        color: ${c.base04};
        padding: 0 14px;
      }

      #custom-notification.notification,
      #custom-notification.inhibited-notification {
        color: ${c.base0E};
      }

      #custom-notification.dnd-notification,
      #custom-notification.dnd-inhibited-notification {
        color: ${c.base09};
      }

      #custom-notification.dnd-none,
      #custom-notification.dnd-inhibited-none {
        color: ${c.base03};
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        background: ${c.base08};
      }

      tooltip {
        background: ${c.base01};
        border: 1px solid ${c.base0D};
        border-radius: 8px;
      }

      tooltip label {
        color: ${c.base05};
        padding: 4px 6px;
      }
    '';
  };
}
