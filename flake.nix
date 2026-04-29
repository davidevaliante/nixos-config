{
  description = "Davide's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pinned to grab packages that broke on unstable. Currently used for
    # neovim — 0.12 in unstable broke nvim-treesitter master's API.
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Pinned to a commit that ships kubectl 1.32.3. Cluster work needs a
    # specific kubectl minor (skew rules); current nixpkgs ships 1.35.x.
    nixpkgs-kubectl.url = "github:NixOS/nixpkgs/ebe4301cbd8f81c4f8d3244b3632338bbeb6d49c";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-plugins = {
      url = "github:noctalia-dev/noctalia-plugins";
      flake = false;
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, ... }:
    let
      lib = nixpkgs.lib;

      mkHost =
        { hostname
        , system ? "x86_64-linux"
        , username ? "davide"
        , extraModules ? [ ]
        }:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs self username hostname; };
          modules = [
            ./hosts/${hostname}
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "hm-bak";
              home-manager.extraSpecialArgs = {
                inherit inputs self username hostname;
              };
              home-manager.users.${username} = import ./home/${username};
            }
          ] ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        hydrogen = mkHost { hostname = "hydrogen"; };
      };
    };
}
