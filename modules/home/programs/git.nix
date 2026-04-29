{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "davide";
        email = "dav.valiante@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rerere.enabled = true;
      diff.algorithm = "histogram";
      column.ui = "auto";
      branch.sort = "-committerdate";
    };

    # Global gitignore — keeps Nix-only artifacts out of unrelated work repos
    # without per-project .gitignore edits. Force-add (`git add -f`) if you
    # ever genuinely want one of these committed.
    ignores = [
      "flake.nix"
      "flake.lock"
      ".envrc"
      ".direnv/"
    ];
  };
}
