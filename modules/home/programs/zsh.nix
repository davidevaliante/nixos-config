{ ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    shellAliases = {
      # nix-switch (modules/home/programs/nix-switch.nix) reads /etc/hostname
      # so the same aliases work on every host without hardcoding the flake target.
      rebuild     = "nix-switch";
      rebuildup   = "nix-switch update";
      rebuildboot = "nix-switch boot";
      rebuilddry  = "nix-switch dry";
      zz = "cd ..";
      zzz = "cd ../..";

      # kitten ssh copies kitty's terminfo to the remote on connect, so
      # `clear`/ncurses programs stop erroring with `'xterm-kitty': unknown
      # terminal type` on servers that lack the entry.
      ssh = "kitten ssh";
    };

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
      # `path` is set centrally in xdg-cleanup.nix to land under
      # XDG_STATE_HOME — keeping the value here would split the source of
      # truth.
    };

    initContent = ''
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      bindkey '^P' history-substring-search-up
      bindkey '^N' history-substring-search-down
    '';
  };
}
