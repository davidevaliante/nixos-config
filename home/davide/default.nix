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
    ../../modules/home/desktop
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.packages = with pkgs; [
    claude-code
  ];

  programs.home-manager.enable = true;

  gtk.gtk4.theme = null;

  home.stateVersion = "25.11";
}
