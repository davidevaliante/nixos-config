{ inputs, pkgs, ... }:

{
  # opentofu pinned to 1.9.1 via the nixpkgs-opentofu flake input.
  # For projects that need a different minor, ship a local flake.nix +
  # `.envrc` (`use flake`) — direnv will swap opentofu on cd.
  home.packages = [
    inputs.nixpkgs-opentofu.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opentofu
  ];
}
