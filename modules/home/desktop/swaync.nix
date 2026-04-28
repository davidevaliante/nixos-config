{ config, lib, ... }:

let
  c = config.lib.stylix.colors.withHashtag;
in
{
  stylix.targets.swaync.enable = lib.mkForce false;

  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "overlay";
      control-center-margin-top = 8;
      control-center-margin-bottom = 8;
      control-center-margin-right = 8;
      control-center-width = 400;
      control-center-height = 720;
      notification-window-width = 400;
      notification-icon-size = 32;
      notification-body-image-height = 120;
      notification-body-image-width = 220;
      timeout = 4;
      timeout-low = 3;
      timeout-critical = 0;
      fit-to-screen = true;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = true;

      widgets = [ "title" "dnd" "notifications" ];

      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear all";
        };
        dnd = {
          text = "Do Not Disturb";
        };
        label = {
          max-lines = 5;
          text = "";
        };
        mpris = {
          image-size = 96;
          image-radius = 12;
        };
      };
    };

    style = ''
      * {
        font-family: "Inter", "JetBrainsMono Nerd Font";
        font-size: 14px;
        outline: none;
      }

      /* ═══ Live toasts ═══ */
      .notification-row {
        outline: none;
        margin: 8px 14px;
        padding: 0;
        background: transparent;
      }

      .notification-row:focus,
      .notification-row:hover {
        background: transparent;
      }

      .notification {
        margin: 0;
        padding: 0;
        border: 2px solid transparent;
        border-radius: 16px;
        background:
          linear-gradient(${c.base01}, ${c.base01}) padding-box,
          linear-gradient(135deg, ${c.base0D} 0%, ${c.base0E} 50%, ${c.base0C} 100%) border-box;
        box-shadow:
          0 12px 28px rgba(0, 0, 0, 0.45),
          0 4px 8px rgba(0, 0, 0, 0.30),
          inset 0 1px 0 alpha(${c.base05}, 0.04);
      }

      .notification.low {
        background:
          linear-gradient(${c.base01}, ${c.base01}) padding-box,
          linear-gradient(135deg, ${c.base03} 0%, ${c.base02} 100%) border-box;
      }

      .notification.critical {
        background:
          linear-gradient(alpha(${c.base08}, 0.10), ${c.base01} 35%) padding-box,
          linear-gradient(135deg, ${c.base08} 0%, ${c.base09} 50%, ${c.base08} 100%) border-box;
        box-shadow:
          0 0 0 1px alpha(${c.base08}, 0.25),
          0 12px 28px alpha(${c.base08}, 0.20),
          0 4px 8px rgba(0, 0, 0, 0.40);
      }

      .notification-content {
        background: transparent;
        padding: 14px;
        border-radius: 14px;
      }

      .notification-content image {
        border-radius: 8px;
        margin-right: 12px;
      }

      .summary {
        font-size: 14px;
        font-weight: 700;
        color: ${c.base05};
        text-shadow: none;
      }

      .time {
        font-size: 11px;
        font-weight: 500;
        color: ${c.base04};
        margin-right: 18px;
      }

      .body {
        font-size: 13px;
        font-weight: 400;
        color: ${c.base04};
        margin-top: 4px;
      }

      .body-image {
        margin-top: 8px;
        border-radius: 10px;
      }

      .close-button {
        background: alpha(${c.base02}, 0.6);
        color: ${c.base04};
        text-shadow: none;
        padding: 0;
        border-radius: 100%;
        margin-top: 8px;
        margin-right: 8px;
        box-shadow: none;
        border: none;
        min-width: 24px;
        min-height: 24px;
        transition: all 200ms ease;
      }

      .close-button:hover {
        background: ${c.base08};
        color: ${c.base00};
        box-shadow: 0 0 12px alpha(${c.base08}, 0.6);
      }

      .notification-action {
        background: ${c.base02};
        color: ${c.base05};
        border: none;
        border-radius: 10px;
        margin: 4px;
        padding: 6px 12px;
        transition: all 180ms ease;
      }

      .notification-action:hover {
        background: linear-gradient(135deg, ${c.base0D}, ${c.base0E});
        color: ${c.base00};
        box-shadow: 0 4px 12px alpha(${c.base0E}, 0.35);
      }

      .notification-default-action {
        margin: 0;
        padding: 0;
        border-radius: 14px;
        background: transparent;
      }

      .notification-default-action:hover {
        background: alpha(${c.base02}, 0.4);
      }

      /* ═══ Control center panel (Super+N) ═══ */
      .control-center {
        padding: 14px;
        border: 2px solid transparent;
        border-radius: 18px;
        background:
          linear-gradient(180deg,
            alpha(${c.base00}, 0.96) 0%,
            alpha(${c.base01}, 0.96) 100%) padding-box,
          linear-gradient(135deg, ${c.base0D} 0%, ${c.base0E} 50%, ${c.base0C} 100%) border-box;
        box-shadow:
          0 16px 48px rgba(0, 0, 0, 0.55),
          0 6px 16px rgba(0, 0, 0, 0.35);
      }

      .control-center-list {
        background: transparent;
      }

      .control-center-list-placeholder {
        opacity: 0.5;
        color: ${c.base04};
      }

      .floating-notifications {
        background: transparent;
      }

      /* widget: title — gradient text via foreground would need pango;
         use gradient on button background and accent border under title */
      .widget-title {
        margin: 4px 6px 14px 6px;
        font-size: 16px;
        font-weight: 700;
        color: ${c.base05};
      }

      .widget-title > label {
        margin-bottom: 6px;
      }

      .widget-title > button {
        background: linear-gradient(135deg, ${c.base02}, ${c.base01});
        color: ${c.base05};
        border: 1px solid ${c.base02};
        border-radius: 10px;
        padding: 5px 14px;
        font-size: 12px;
        font-weight: 500;
        transition: all 200ms ease;
      }

      .widget-title > button:hover {
        background: linear-gradient(135deg, ${c.base08}, ${c.base09});
        color: ${c.base00};
        border: 1px solid alpha(${c.base08}, 0.5);
        box-shadow: 0 4px 12px alpha(${c.base08}, 0.30);
      }

      /* widget: do not disturb */
      .widget-dnd {
        margin: 0 6px 12px 6px;
        font-size: 13px;
        color: ${c.base04};
      }

      .widget-dnd > switch {
        background: ${c.base02};
        border: 1px solid alpha(${c.base02}, 0.8);
        border-radius: 100px;
        min-width: 42px;
        min-height: 22px;
        transition: all 200ms ease;
      }

      .widget-dnd > switch:checked {
        background: linear-gradient(135deg, ${c.base0D}, ${c.base0E});
        border: 1px solid alpha(${c.base0E}, 0.5);
        box-shadow: 0 0 12px alpha(${c.base0E}, 0.35);
      }

      .widget-dnd > switch slider {
        background: ${c.base05};
        border-radius: 100px;
        min-width: 18px;
        min-height: 18px;
      }

      /* widget: label */
      .widget-label > label {
        color: ${c.base04};
        font-size: 12px;
      }

      /* media player */
      .widget-mpris {
        background: linear-gradient(135deg,
          alpha(${c.base02}, 0.6),
          alpha(${c.base01}, 0.8));
        border: 1px solid alpha(${c.base02}, 0.5);
        border-radius: 14px;
        padding: 12px;
        margin: 6px 6px 10px 6px;
      }

      .widget-mpris-player {
        background: transparent;
        padding: 0;
      }

      .widget-mpris-title {
        color: ${c.base05};
        font-weight: 700;
        font-size: 14px;
      }

      .widget-mpris-subtitle {
        color: ${c.base04};
        font-size: 12px;
      }

      /* progress bars */
      progress, trough {
        border-radius: 100px;
        min-height: 6px;
      }

      trough {
        background: ${c.base02};
      }

      progress {
        background: linear-gradient(90deg, ${c.base0D}, ${c.base0E});
        box-shadow: 0 0 8px alpha(${c.base0E}, 0.4);
      }

      scrolledwindow undershoot,
      scrolledwindow overshoot {
        background: none;
      }
    '';
  };
}
