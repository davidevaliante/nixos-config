# Per-project dev environments, exposed as flake outputs so external
# project repos can reference them without committing any Nix files.
#
# Usage in an external project repo (e.g. ~/work/fe-stack):
#
#   echo 'use flake ~/nixos-config#fe-stack' > .envrc
#   direnv allow
#
# Add `.envrc` and `.direnv/` to your global gitignore (~/.config/git/ignore)
# so they don't show up as untracked in any project. The dev shell then
# activates automatically on cd; collaborators see no Nix files.
#
# Why this lives in nixos-config rather than in each project's flake:
#   • Single source of truth — toolchain bumps happen once, every project
#     using the shell follows along.
#   • Project repos stay clean — non-Nix collaborators don't see flake
#     files they don't care about.
#   • Synced across hosts via the system flake — hydrogen and helium both
#     have the dev shells available without separate plumbing.
#
# Tradeoff: per-project lock pinning is lost. If a project genuinely needs
# Node 20.11.1 *exactly* alongside that branch, that project should ship
# its own flake.nix instead.

{ ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      devShells = {
        # Example shell — clone and rename per project. Currently mirrors
        # what `home/davide/default.nix` ships globally, so it's a no-op
        # placeholder; swap in a different `nodejs_*` to demonstrate the
        # per-project isolation.
        fe-stack = pkgs.mkShell {
          # Tauri's Rust crates link system libs at build time — pkg-config
          # needs to find their .pc files, which on NixOS only land in
          # PKG_CONFIG_PATH when the dev outputs are pulled into a shell.
          nativeBuildInputs = with pkgs; [ pkg-config ];
          buildInputs = with pkgs; [
            glib
            gtk3
            webkitgtk_4_1 # Tauri v2 targets webkit2gtk-4.1
            libsoup_3
            librsvg
            cairo
            pango
            gdk-pixbuf
            atk
            openssl
          ];

          packages = with pkgs; [
            nodejs_24
            corepack_24 # activates pnpm/yarn pinned via package.json packageManager
            cargo
            rustc
          ];

          shellHook = ''
            echo "fe-stack devshell — node $(node --version), corepack $(corepack --version)"
          '';
        };
        test-shell = pkgs.mkShell {
          packages = with pkgs; [
            cowsay
          ];
        };
      };
    };
}
