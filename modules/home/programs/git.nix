{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "davidevaliante";
        email = "dav.valiante@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      rerere.enabled = true;
      diff.algorithm = "histogram";
      column.ui = "auto";
      branch.sort = "-committerdate";
      protocol.version = 2;

      credential = {
        helper = "!aws codecommit credential-helper $@";
        useHttpPath = true;
      };

      # Force SSH for AWS CodeCommit even when remotes are configured with HTTPS.
      url = {
        "ssh://git-codecommit.eu-central-1.amazonaws.com/".insteadOf =
          "https://git-codecommit.eu-central-1.amazonaws.com/";
        "ssh://git-codecommit.eu-central-1.amazonaws.com/v1/repos/".insteadOf =
          "git-codecommit.eu-central-1.amazonaws.com/v1/repos/";
      };
    };

    # Global gitignore — keeps Nix-only artifacts out of unrelated work repos
    # without per-project .gitignore edits. Force-add (`git add -f`) if you
    # ever genuinely want one of these committed.
    ignores = [
      "flake.nix"
      "flake.lock"
      ".envrc"
      ".direnv/"
      "CLAUDE.md"
      ".claude/"
    ];
  };
}
