{ lib, ... }:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    # Default command is `z`. Don't override with --cmd.
  };

  # Our z() override is placed *after* zoxide's init by design; suppress
  # zoxide's `doctor` warning that flags this as a "possible config issue".
  home.sessionVariables._ZO_DOCTOR = "0";

  # Override zoxide's `z` so calling it with no arguments goes $HOME instead of
  # the most-frecent directory. lib.mkAfter ensures this runs *after* zoxide's
  # integration installs its own `z` function.
  programs.zsh.initContent = lib.mkAfter ''
    z() {
      if [ "$#" -eq 0 ]; then
        builtin cd -- "$HOME"
      else
        __zoxide_z "$@"
      fi
    }
  '';
}
