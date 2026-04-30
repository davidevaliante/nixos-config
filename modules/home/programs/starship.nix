{ lib, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    # Settings here override stylix's defaults; we deliberately omit any
    # color/style fields so stylix keeps full control of the palette.
    settings = {
      add_newline = false;

      character = {
        # Stylix sets up a `base16` palette in starship, so we can reference
        # theme colors by name. base09 = Oxocarbon pink (matches cursor),
        # base08 = red for error symbol.
        success_symbol = "[λ](bold base09)";
        error_symbol = "[✗](bold base08)";
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        read_only = " 󰌾";
      };

      hostname.ssh_symbol = " ";

      # ── Language / runtime symbols ──
      aws        = { symbol = "  "; disabled = true; };
      buf        = { symbol = " "; };
      c          = { symbol = " "; };
      conda      = { symbol = " "; };
      crystal    = { symbol = " "; };
      dart       = { symbol = " "; };
      docker_context = { symbol = " "; };
      elixir     = { symbol = " "; };
      elm        = { symbol = " "; };
      fennel     = { symbol = " "; };
      fossil_branch = { symbol = " "; };
      git_branch = { symbol = " "; };
      golang     = { symbol = " "; };
      guix_shell = { symbol = " "; };
      haskell    = { symbol = " "; };
      haxe       = { symbol = " "; };
      hg_branch  = { symbol = " "; };
      java       = { symbol = " "; };
      julia      = { symbol = " "; };
      kotlin     = { symbol = " "; };
      lua        = { symbol = " "; };
      memory_usage = { symbol = "󰍛 "; };
      meson      = { symbol = "󰔷 "; };
      nim        = { symbol = "󰆥 "; };
      nix_shell  = { symbol = " "; };
      nodejs     = { symbol = " "; };
      ocaml      = { symbol = " "; };
      package    = { symbol = "󰏗 "; };
      perl       = { symbol = " "; };
      php        = { symbol = " "; };
      pijul_channel = { symbol = " "; };
      python     = { symbol = " "; };
      rlang      = { symbol = "󰟔 "; };
      ruby       = { symbol = " "; };
      rust       = { symbol = " "; };
      scala      = { symbol = " "; };
      swift      = { symbol = " "; };
      zig        = { symbol = " "; };

      # ── OS symbols ──
      os.symbols = {
        Alpaquita = " ";
        Alpine = " ";
        Amazon = " ";
        Android = " ";
        Arch = " ";
        Artix = " ";
        CentOS = " ";
        Debian = " ";
        DragonFly = " ";
        Emscripten = " ";
        EndeavourOS = " ";
        Fedora = " ";
        FreeBSD = " ";
        Garuda = "󰛓 ";
        Gentoo = " ";
        HardenedBSD = "󰞌 ";
        Illumos = "󰈸 ";
        Linux = " ";
        Mabox = " ";
        Macos = " ";
        Manjaro = " ";
        Mariner = " ";
        MidnightBSD = " ";
        Mint = " ";
        NetBSD = " ";
        NixOS = " ";
        OpenBSD = "󰈺 ";
        openSUSE = " ";
        OracleLinux = "󰌷 ";
        Pop = " ";
        Raspbian = " ";
        Redhat = " ";
        RedHatEnterprise = " ";
        Redox = "󰀘 ";
        Solus = "󰠳 ";
        SUSE = " ";
        Ubuntu = " ";
        Unknown = " ";
        Windows = "󰍲 ";
      };
    };
  };
}
