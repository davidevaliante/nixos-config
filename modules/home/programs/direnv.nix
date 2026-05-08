{ ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
  };

  # Force-set via zsh's .zshenv (sourced by every zsh, login or not) so
  # nothing else — sessionVariables, a stale systemd user env, an old
  # shell init — can leave a broken literal-`\033` value in place.
  # Plain text only: direnv's Go logger doesn't interpret backslash
  # escapes in the format string, so any \033 sequences would render
  # verbatim. Trade colors for guaranteed-readable output.
  programs.zsh.envExtra = ''
    export DIRENV_LOG_FORMAT="direnv: %s"
  '';
}
