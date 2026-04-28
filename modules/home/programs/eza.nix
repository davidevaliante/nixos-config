{ ... }:

let
  # Shared flag set baked into every alias so behaviour stays consistent.
  eza = "eza --group-directories-first --time-style=long-iso --icons=auto --git";
in
{
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };

  home.shellAliases = {
    # Replacements for ls
    ls   = eza;
    l    = "${eza} -l --header";
    ll   = "${eza} -l --header";
    la   = "${eza} -la --header";
    ld   = "${eza} -lD --header";          # only directories
    lf   = "${eza} -lf --header";          # only files

    # Tree views
    lt   = "${eza} --tree --level=2";
    llt  = "${eza} -l --tree --level=2 --header";
    lt3  = "${eza} --tree --level=3";
    tree = "${eza} --tree";

    # Git-aware
    lg   = "${eza} -l --git-ignore --header";   # respect .gitignore
  };
}
