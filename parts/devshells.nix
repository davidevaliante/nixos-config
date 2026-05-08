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

{ inputs, ... }:

{
  perSystem =
    { pkgs, system, ... }:
    let
      # Version-pinned tools for cluster work. Cluster API skew rules and
      # tofu state-file compatibility tie us to specific minors, so we pull
      # these from dedicated nixpkgs inputs instead of the rolling unstable.
      pkgs-kubectl = import inputs.nixpkgs-kubectl { inherit system; };
      pkgs-opentofu = import inputs.nixpkgs-opentofu { inherit system; };

      # Builds libprng.so + libprng.h from the `prng` Go source repo.
      # game-service links against this via cgo. Mirrors the upstream
      # makefile's `so` target: `go build -buildmode=c-shared cmd/sharedlib`.
      libprng = pkgs.buildGoModule {
        pname = "libprng";
        version = inputs.prng.shortRev or "dirty";
        src = inputs.prng;

        # Bump when prng's go.sum changes — nix will print the new hash
        # on mismatch.
        vendorHash = "sha256-UK4yJ5X5wfYLA9ywPMjhNcZGU4QQELIfTRr6sOPZ8PQ=";

        # buildGoModule defaults to producing executables; override to emit
        # a c-shared library and copy the cgo-generated header alongside.
        buildPhase = ''
          runHook preBuild
          go build -buildmode=c-shared \
            -ldflags="-s -w -X main.hash=${inputs.prng.rev or "unknown"}" \
            -o libprng.so \
            ./cmd/sharedlib
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out/lib $out/include
          cp libprng.so $out/lib/
          cp libprng.h  $out/include/
          runHook postInstall
        '';

        doCheck = false;
      };
    in
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
        # Shell for topgaming/backend/game-service. Provides Go + air for
        # hot reload, plus libprng wired into cgo via env vars so
        # `go build` / `air` find the shared library without the manual
        # /usr/local/lib install dance from INSTALL_LIBPRNG.md.
        game-service = pkgs.mkShell {
          packages = with pkgs; [
            go
            air
            pkg-config
          ];

          # cgo needs the header at compile time and the .so at link/run
          # time. LD_LIBRARY_PATH lets the unwrapped binary find libprng.so
          # when run from the shell (air rebuilds and re-execs `tmp/main`).
          CGO_CFLAGS = "-I${libprng}/include";
          CGO_LDFLAGS = "-L${libprng}/lib -lprng";
          LD_LIBRARY_PATH = "${libprng}/lib";

          shellHook = ''
            echo "game-service devshell — go $(go version | awk '{print $3}'), air $(air -v 2>&1 | head -n1)"
            echo "libprng: ${libprng}"
          '';
        };

        # Shell for topgaming/eks — terraform/opentofu state lives in this
        # repo and the runbook in readme.md drives EKS via aws + kubectl.
        # Pinning the toolchain here keeps `tofu apply` reproducible across
        # hydrogen/helium instead of leaning on whatever's globally installed.
        topgaming-eks = pkgs.mkShell {
          name = "topgaming-eks";
          packages = [
            pkgs.awscli2
            pkgs-kubectl.kubectl
            pkgs.eksctl
            pkgs-opentofu.opentofu
            # kubectx + kubens for quick context/namespace switching.
            # Auto-uses fzf for interactive picking when fzf is on PATH.
            pkgs.kubectx
            pkgs.fzf
          ];

          shellHook = ''
            # Directory-scoped default kubectl context. Layer a per-project
            # override file (only `current-context`) on top of ~/.kube/config
            # via KUBECONFIG so this shell defaults to dev-eks without
            # mutating the global config that other terminals share.
            # Always overwritten on entry so "default" really is the default;
            # use `kubectx` inside the shell to flip — those writes land in
            # the override file (first in KUBECONFIG) and are reset on
            # re-entry.
            # Caveat: `aws eks update-kubeconfig` would write to the first
            # file in KUBECONFIG. Pass `--kubeconfig ~/.kube/config` when
            # updating the global config from inside this shell.
            CTX_FILE="$PWD/.direnv/kubeconfig-ctx"
            mkdir -p "$(dirname "$CTX_FILE")"
            cat > "$CTX_FILE" <<'EOF'
            apiVersion: v1
            kind: Config
            clusters: []
            contexts: []
            users: []
            current-context: arn:aws:eks:eu-central-1:530145339946:cluster/dev-eks
            EOF
            export KUBECONFIG="$CTX_FILE:$HOME/.kube/config"

            echo "topgaming-eks devshell — aws $(aws --version 2>&1 | awk '{print $1}'), kubectl $(kubectl version --client 2>/dev/null | awk '/Client Version/{print $3}'), tofu $(tofu version | awk 'NR==1{print $2}'), ctx $(kubectl config current-context 2>/dev/null || echo unset)"
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
