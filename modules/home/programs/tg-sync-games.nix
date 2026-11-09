{ pkgs, ... }:

let
  # Clone/update every TopGaming frontend game on its branch and report what
  # changed. The game list lives at the top of tg-sync-games.sh — edit it
  # there and rebuild.
  tgSyncGames = pkgs.writeShellApplication {
    name = "tg-sync-games";
    runtimeInputs = with pkgs; [
      git
      git-lfs
      coreutils # du, wc, tr, cut
      gawk
      gnugrep
      gnused
    ];
    text = builtins.readFile ./tg-sync-games.sh;
  };
in
{
  home.packages = [ tgSyncGames ];
}
