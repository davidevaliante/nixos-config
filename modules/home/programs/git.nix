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
  };
}
