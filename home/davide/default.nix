{ pkgs, username, ... }:

{
  imports = [
    ../../modules/home/programs/zsh.nix
    ../../modules/home/programs/starship.nix
    ../../modules/home/programs/eza.nix
    ../../modules/home/programs/zoxide.nix
    ../../modules/home/programs/bottom.nix
    ../../modules/home/programs/neovim.nix
    ../../modules/home/programs/git.nix
    ../../modules/home/programs/direnv.nix
    ../../modules/home/programs/nix-switch.nix
    ../../modules/home/programs/ssh.nix
    ../../modules/home/programs/fzf.nix
    ../../modules/home/programs/awsp.nix
    ../../modules/home/programs/kubectl.nix
    ../../modules/home/programs/opentofu.nix
    ../../modules/home/programs/kubeconfig.nix
    ../../modules/home/programs/bootstrap.nix
    ../../modules/home/programs/obs.nix
    ../../modules/home/xdg-cleanup.nix
    ../../modules/home/desktop
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.packages = with pkgs; [
    claude-code
    slack
    google-chrome
    apidog
    nvd          # diff between two NixOS generations

    # Dev toolchains. nvm/fnm are intentionally excluded — they ship glibc Node
    # binaries that can't run on NixOS. Per-project version pinning is handled
    # via flake.nix + nix-direnv, not these globals.
    # Match claude-code's Node version (it ships nodejs_24 as a runtime dep);
    # mismatched majors collide on `include/node/common.gypi` in buildEnv.
    nodejs_24
    corepack_24 # activates pnpm/yarn versions pinned in package.json's packageManager field
    go
    rustup

    awscli2

    authenticator   # TOTP/HOTP codes (GNOME/libadwaita, themed via stylix)
  ];

  home.sessionVariables.BROWSER = "google-chrome-stable";

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";
      "x-scheme-handler/apidog" = "apidog.desktop";
    };
  };

  # The apidog nixpkgs package ships the binary + icon but no .desktop
  # entry, so launchers (fuzzel, etc.) can't see it. Provide one ourselves.
  xdg.desktopEntries.apidog = {
    name = "Apidog";
    genericName = "API Client";
    comment = "All-in-one API design, test, mock and documentation platform";
    exec = "apidog %U";
    icon = "apidog";
    type = "Application";
    startupNotify = true;
    categories = [ "Development" "Network" ];
    # Required for OAuth callback (apidog://...) to route from Chrome back
    # into the running Apidog instance.
    mimeType = [ "x-scheme-handler/apidog" ];
    settings.StartupWMClass = "Apidog";
  };

  mySystem.desktop.shell = "noctalia";

  programs.home-manager.enable = true;

  gtk.gtk4.theme = null;

  home.stateVersion = "25.11";
}
