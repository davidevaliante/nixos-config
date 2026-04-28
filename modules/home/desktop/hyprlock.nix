{ lib, config, ... }:

let
  c = config.lib.stylix.colors;
in
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        disable_loading_bar = true;
        grace = 5;
        hide_cursor = true;
        no_fade_in = false;
      };

      label = lib.mkAfter [
        # Time — large, centered, accent color, soft shadow
        {
          monitor = "";
          text = "$TIME";
          color = "rgba(${c.base05}ff)";
          font_size = 110;
          font_family = "JetBrainsMono Nerd Font ExtraBold";
          position = "0, 280";
          halign = "center";
          valign = "center";
          shadow_passes = 3;
          shadow_size = 6;
          shadow_color = "rgba(${c.base00}cc)";
          shadow_boost = 1.3;
        }
        # Date — under the time, muted
        {
          monitor = "";
          text = ''cmd[update:60000] date +"%A, %B %d"'';
          color = "rgba(${c.base04}ff)";
          font_size = 22;
          font_family = "Inter Medium";
          position = "0, 180";
          halign = "center";
          valign = "center";
        }
        # Greeting near input field, accent color
        {
          monitor = "";
          text = "Hi, $USER ";
          color = "rgba(${c.base0E}ff)";
          font_size = 18;
          font_family = "Inter SemiBold";
          position = "0, -130";
          halign = "center";
          valign = "center";
        }
      ];

      # Subtle accent divider between time and greeting
      shape = lib.mkAfter [
        {
          monitor = "";
          size = "200, 2";
          color = "rgba(${c.base0D}aa)";
          rounding = 2;
          border_size = 0;
          position = "0, 100";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
