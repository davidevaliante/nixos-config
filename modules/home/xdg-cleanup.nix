{ config, ... }:

let
  xdgConfig = "${config.home.homeDirectory}/.config";
  xdgState  = "${config.home.homeDirectory}/.local/state";
  xdgData   = "${config.home.homeDirectory}/.local/share";
  xdgCache  = "${config.home.homeDirectory}/.cache";
in
{
  # `xdg.enable` exports XDG_CONFIG_HOME / DATA / STATE / CACHE and creates
  # the dirs. Many programs honor these out of the box once set.
  xdg.enable = true;

  # Move zsh dotfiles into ~/.config/zsh; HISTFILE goes under XDG_STATE_HOME
  # so the history isn't mixed with config.
  programs.zsh.dotDir = ".config/zsh";
  programs.zsh.history.path = "${xdgState}/zsh/history";

  home.sessionVariables = {
    # Rust toolchain (rustup populates this; cargo also looks at CARGO_HOME).
    RUSTUP_HOME = "${xdgData}/rustup";
    CARGO_HOME  = "${xdgData}/cargo";

    # npm — global install prefix lives under data, cache under cache.
    NPM_CONFIG_CACHE  = "${xdgCache}/npm";
    NPM_CONFIG_PREFIX = "${xdgData}/npm";

    # GTK2 (GTK3+ already reads from XDG_CONFIG_HOME).
    GTK2_RC_FILES = "${xdgConfig}/gtk-2.0/gtkrc";

    # less / readline / wget history (small but pollute $HOME).
    LESSHISTFILE = "${xdgState}/less/history";
    WGETRC       = "${xdgConfig}/wget/wgetrc";
    INPUTRC      = "${xdgConfig}/readline/inputrc";

    # bash — barely used, but the file appears.
    HISTFILE = "${xdgState}/bash/history";
  };
}
