{ ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
  };

  home.sessionVariables.DIRENV_LOG_FORMAT = "\\033[38;5;240mdirenv: %s\\033[0m";
}
