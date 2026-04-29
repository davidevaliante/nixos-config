{ inputs, pkgs, ... }:

{
  # kubectl pinned to 1.32.x via the nixpkgs-kubectl flake input.
  # For projects that need a different minor, ship a local flake.nix +
  # `.envrc` (`use flake`) — direnv will swap kubectl on cd.
  home.packages = [
    inputs.nixpkgs-kubectl.legacyPackages.${pkgs.system}.kubectl
  ];
}
