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
  # so the history isn't mixed with config. dotDir wants an absolute path
  # — relative is deprecated in newer home-manager.
  programs.zsh.dotDir = "${xdgConfig}/zsh";
  programs.zsh.history.path = "${xdgState}/zsh/history";

  # GTK2 — home-manager's gtk2 module owns GTK2_RC_FILES; setting this option
  # makes it write the rc file there *and* update the env var consistently.
  gtk.gtk2.configLocation = "${xdgConfig}/gtk-2.0/gtkrc";

  home.sessionVariables = {
    # Rust toolchain (rustup populates this; cargo also looks at CARGO_HOME).
    RUSTUP_HOME = "${xdgData}/rustup";
    CARGO_HOME  = "${xdgData}/cargo";

    # npm — global install prefix lives under data, cache under cache.
    NPM_CONFIG_CACHE  = "${xdgCache}/npm";
    NPM_CONFIG_PREFIX = "${xdgData}/npm";

    # less / readline / wget history (small but pollute $HOME).
    LESSHISTFILE = "${xdgState}/less/history";
    WGETRC       = "${xdgConfig}/wget/wgetrc";
    INPUTRC      = "${xdgConfig}/readline/inputrc";

    # bash — barely used, but the file appears.
    HISTFILE = "${xdgState}/bash/history";
  };
}
