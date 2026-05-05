{ ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    shellAliases = {
      rebuild     = "sudo nixos-rebuild switch --flake /home/davide/nixos-config#hydrogen";
      rebuildup   = "sudo nix flake update --flake /home/davide/nixos-config && sudo nixos-rebuild switch --flake /home/davide/nixos-config#hydrogen";
      rebuildboot = "sudo nixos-rebuild boot --flake /home/davide/nixos-config#hydrogen";
      rebuilddry  = "sudo nixos-rebuild build --flake /home/davide/nixos-config#hydrogen";
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
