{ config, pkgs, ... }:

{
  home.username = "davide";
  home.homeDirectory = "/home/davide";

  home.packages = with pkgs; [
    claude-code
  ];

  programs.home-manager.enable = true;

  home.stateVersion = "25.11";
}
