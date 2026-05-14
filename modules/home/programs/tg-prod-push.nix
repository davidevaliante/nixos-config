{ pkgs, ... }:

let
  tgProdPush = pkgs.writeShellApplication {
    name = "tg-prod-push";
    runtimeInputs = with pkgs; [
      awscli2
      docker        # CLI; daemon comes from virtualisation.docker (cosmo.nix)
      coreutils     # tr, timeout
      gnugrep
    ];
    text = builtins.readFile ./tg-prod-push.sh;
  };
in
{
  home.packages = [ tgProdPush ];
}
