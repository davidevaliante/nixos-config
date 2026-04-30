{ pkgs, lib, ... }:

{
  # Fuzzel is always enabled (themed via stylix) so ad-hoc prompts in helper
  # scripts like `niri-workspace-rename` look consistent. On the noctalia
  # shell, the launcher itself is noctalia's panel — fuzzel is only the
  # fallback / generic prompt.
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        layer = "overlay";
        terminal = "kitty";
        prompt = "'  '";
        icon-theme = "Papirus-Dark";
        icons-enabled = "yes";
        width = 42;
        lines = 10;
        line-height = 26;
        font = lib.mkForce "Inter:weight=500:size=13";
        fields = "name,generic,categories,filename,keywords";
        horizontal-pad = 26;
        vertical-pad = 22;
        inner-pad = 14;
        image-size-ratio = 0.5;
        tabs = 4;
        placeholder = "Search applications";
      };
      border = {
        radius = 16;
        width = 2;
      };
      dmenu = {
        exit-immediately-if-empty = "yes";
      };
    };
  };

  home.packages = with pkgs; [ papirus-icon-theme ];
}
