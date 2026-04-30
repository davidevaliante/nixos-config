{ ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    shellAliases = {
      # `nh` wraps nixos-rebuild with colored phase output and an
      # automatic generation diff via nvd. NH_FLAKE is set by
      # programs.nh.flake, so no --flake needed.
      rebuild     = "nh os switch";
      rebuildup   = "nh os switch -u";        # also update flake.lock
      rebuildboot = "nh os boot";             # apply on next boot
      rebuilddry  = "nh os build";            # build only, no activation
      zz = "cd ..";
      zzz = "cd ../..";
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
