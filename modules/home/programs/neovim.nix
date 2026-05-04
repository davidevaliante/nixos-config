{ pkgs, lib, inputs, ... }:

let
  pkgsStable = import inputs.nixpkgs-stable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  # Stylix's neovim target writes a base16 theme into ~/.config/nvim/init.lua,
  # which fights a hand-curated lua config. We theme nvim from inside the lua
  # config instead (e.g. via the user's preferred colorscheme plugin).
  stylix.targets.neovim.enable = lib.mkForce false;

  # Don't use programs.neovim — it generates an init.lua wrapper that conflicts
  # with the user's own ~/.config/nvim/init.lua. Install nvim as a plain package
  # plus everything the lua config + plugins expect at runtime.
  #
  # Neovim is pinned to the 25.11 release (0.11.x). Unstable has 0.12 which
  # introduced breaking treesitter API changes that nvim-treesitter master
  # hasn't caught up with yet.
  home.packages = [ pkgsStable.neovim ] ++ (with pkgs; [

    # ── Build deps for tree-sitter parser compilation & native plugins ──
    gcc
    gnumake
    libtool
    pkg-config

    # ── Languages / runtimes plugins shell out to ──
    nodejs                # cmp/copilot/many node-based plugins
    python3               # pyright fallback, plenary
    tree-sitter           # CLI for nvim-treesitter

    # ── LSPs (config calls them via nvim-lspconfig — Mason auto-install fails
    #     on NixOS, but with these in PATH lspconfig finds them directly) ──
    lua-language-server                   # lua_ls
    typescript-language-server            # ts_ls
    vscode-langservers-extracted          # html, cssls, jsonls, eslint
    gopls                                 # gopls
    nginx-language-server                 # nginx_language_server
    nixd                                  # nixd — option/package completion against this flake
    nixfmt                                # nixd's default formatter (opt-in via lspservers/nixd.lua)

    # ── Formatters (conform.nvim) ──
    stylua
    prettierd
    # rustfmt comes from rustup (installed globally); installing it standalone
    # collides on `bin/cargo-fmt` in the user env.
    gofumpt
    # gotools dropped: gopls already provides modernize/goimports

    # ── Search / find (telescope, plugin grepping) ──
    ripgrep
    fd

    # ── Git / utility ──
    lazygit
    delta                                 # diffview/git diff highlighting

    # ── Image rendering (image.nvim) ──
    imagemagick

    # ── Misc ──
    luarocks                              # some plugins use rocks
  ]);

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    MANPAGER = "nvim +Man!";
  };

  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };
}
