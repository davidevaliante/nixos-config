{ pkgs, ... }:

let
  gitPrepushSlack = pkgs.writeShellApplication {
    name = "git-prepush-slack";
    runtimeInputs = with pkgs; [
      awscli2
      jq
      git
      curl
      coreutils # basename, chmod
    ];
    text = builtins.readFile ./git-prepush-slack.sh;
  };
in
{
  home.packages = [ gitPrepushSlack ];
}
