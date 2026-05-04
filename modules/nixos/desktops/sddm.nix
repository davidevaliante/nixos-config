{ pkgs, config, ... }:

let
  c = config.lib.stylix.colors.withHashtag;

  # sddm-astronaut accepts a `themeConfig` attrset that lands as
  # `Themes/<embeddedTheme>.conf.user`, overriding the upstream defaults.
  # We use the plain `astronaut` layout and re-paint every color slot from
  # the active stylix base16 palette, so a `theme switch` propagates here
  # automatically without touching this module.
  astronautOxocarbon = pkgs.sddm-astronaut.override {
    embeddedTheme = "astronaut";
    themeConfig = {
      # Use the stylix-generated gradient wallpaper instead of the bundled image
      Background = "${config.stylix.image}";
      DimBackgroundImage = "0.2";
      ScaleImageCropped = "true";
      ScreenWidth = "1920";
      ScreenHeight = "1080";

      FontFamily = "Inter";
      HeaderText = "Welcome";
      DateFormat = "dddd, MMMM d";
      HourFormat = "HH:mm";
      PartialBlur = "true";
      ForceLastUser = "true";
      ForcePasswordFocus = "true";

      # Core palette
      MainColor = c.base05;        # default text
      AccentColor = c.base0E;      # highlights (purple in Oxocarbon)
      BackgroundColor = c.base00;  # solid bg fallback
      PlaceholderColor = c.base03; # placeholder text in inputs
      WarningColor = c.base08;

      # Header / clock
      HeaderTextColor = c.base05;
      TimeTextColor = c.base05;
      DateTextColor = c.base04;

      # System buttons (power/reboot/sleep)
      IconColor = c.base05;
      SystemButtonsIconsColor = c.base05;
      SessionButtonTextColor = c.base05;
      VirtualKeyboardButtonTextColor = c.base05;

      # Session dropdown
      DropdownBackgroundColor = c.base01;
      DropdownTextColor = c.base05;
      DropdownSelectedBackgroundColor = c.base0E;
      DropdownSelectedTextColor = c.base00;

      # Login / password fields
      LoginFieldBackgroundColor = c.base01;
      LoginFieldTextColor = c.base05;
      PasswordFieldBackgroundColor = c.base01;
      PasswordFieldTextColor = c.base05;
      HoverFieldBackgroundColor = c.base02;
      HoverFieldTextColor = c.base05;

      # Login button (the cyan/purple call-to-action)
      LoginButtonBackgroundColor = c.base0E;
      LoginButtonTextColor = c.base00;

      # Selected/highlighted state inside form
      HighlightBackgroundColor = c.base0E;
      HighlightTextColor = c.base00;
    };
  };
in
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    package = pkgs.kdePackages.sddm;  # qt6 sddm is required by astronaut
    extraPackages = [ astronautOxocarbon ];
  };

  # Astronaut depends on these Qt6 modules at runtime; without them the
  # theme renders blank or falls back to the default.
  environment.systemPackages = with pkgs.kdePackages; [
    qtsvg
    qtmultimedia
    qtvirtualkeyboard
  ];

  # No X server, no GNOME session — niri/Hyprland handle all desktop work.
  # Drops the GNOME service stack (tracker, evolution-data-server, etc.) and
  # also fixes the post-logout hang: GDM's session restart was the piece
  # that left the screen stuck after a noctalia logout.
  services.xserver.enable = false;
}
