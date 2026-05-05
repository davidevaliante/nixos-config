{ pkgs, inputs, lib, config, self, ... }:

let
  defaultTheme = "oxocarbon-dark";

  themes = {
    oxocarbon-dark = "${pkgs.base16-schemes}/share/themes/oxocarbon-dark.yaml";
    catppuccin-mocha = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    tokyo-night-dark = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
    synthwave-84 = ./themes/synthwave-84.yaml;
  };

  themeFile = "${self}/.theme";
  activeTheme =
    if builtins.pathExists themeFile
    then lib.removeSuffix "\n" (builtins.readFile themeFile)
    else defaultTheme;

  selectedScheme = themes.${activeTheme} or themes.${defaultTheme};
in
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  stylix = {
    enable = true;
    autoEnable = true;
    polarity = "dark";

    base16Scheme = selectedScheme;

    image =
      let
        c = config.lib.stylix.colors.withHashtag;
      in
      pkgs.runCommand "wallpaper.png" { } ''
        ${pkgs.imagemagick}/bin/magick \
          -size 3840x2160 \
          gradient:'${c.base0E}'-'${c.base0D}' \
          $out
      '';

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      sizes = {
        applications = 11;
        terminal = 12;
        desktop = 11;
        popups = 11;
      };
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    # Without an icon theme, freedesktop named-icon lookups (e.g.
    # `utilities-terminal` in our kitty .desktop entry) fall through to
    # hicolor and render GTK's pink/black missing-image placeholder.
    # Papirus has near-complete coverage of named icons + stylix-friendly
    # dark/light variants.
    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };

    opacity = {
      terminal = 0.95;
      applications = 1.0;
      popups = 0.95;
      desktop = 1.0;
    };

    targets.qt.platform = lib.mkForce "qtct";
  };
}
