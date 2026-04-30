{ ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    shellAliases = {
      rebuild = "nix-switch";
      rebuildup = "nix-switch update";
      rebuildboot = "nix-switch boot";
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
