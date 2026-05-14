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

      # Factory for per-environment EKS shells. Pins the toolchain, binds an
      # AWS profile + EKS context, and binds a NetworkManager VPN connection
      # via real wrapper scripts so the three things that have to agree
      # (cwd / profile / VPN) stay in sync.
      #
      # Why scripts and not shellHook functions: bash functions defined in a
      # shellHook don't reliably survive nix-direnv → zsh. Wrappers built
      # with writeShellScriptBin are real binaries on PATH that shadow the
      # underlying tools (and stay defined as commands, not functions).
      mkEksShell =
        {
          name,
          awsProfile, # string, or null to leave AWS_PROFILE unset (= default)
          vpnName, # NetworkManager connection name
          kubeCtxArn, # full EKS cluster ARN to pin as current-context
        }:
        let
          nmcli = "${pkgs.networkmanager}/bin/nmcli";

          # Refuses to run the wrapped tool unless the matching VPN
          # connection is active. Inline the check rather than calling a
          # helper so the wrapper has zero runtime dependencies on the
          # shellHook having been sourced.
          guarded =
            { name, realBin }:
            pkgs.writeShellScriptBin name ''
              if ! ${nmcli} -t -f NAME connection show --active 2>/dev/null | grep -qx "${vpnName}"; then
                printf '\033[1;31m!! VPN ${vpnName} is NOT active — refusing to run %s.\033[0m  Run: tg-vpn-up\n' "${name}" >&2
                exit 1
              fi
              exec ${realBin} "$@"
            '';

          # Standalone helpers exposed as binaries so they're callable from
          # any shell (zsh/bash/fish) regardless of how direnv exports.
          tg-vpn-up = pkgs.writeShellScriptBin "tg-vpn-up" ''
            exec ${nmcli} connection up "${vpnName}" "$@"
          '';
          tg-vpn-down = pkgs.writeShellScriptBin "tg-vpn-down" ''
            exec ${nmcli} connection down "${vpnName}" "$@"
          '';
          tg-status = pkgs.writeShellScriptBin "tg-status" ''
            printf '%s — AWS_PROFILE=%s, ctx %s\n' "${name}" "''${AWS_PROFILE:-default}" "${kubeCtxArn}"
            if ${nmcli} -t -f NAME connection show --active 2>/dev/null | grep -qx "${vpnName}"; then
              printf 'VPN ${vpnName}: active\n'
            else
              printf 'VPN ${vpnName}: NOT active (run: tg-vpn-up)\n'
            fi
          '';
        in
        pkgs.mkShell {
          inherit name;
          # Wrapper bins go FIRST so they shadow the unguarded versions in
          # PATH. kubectl/aws/eksctl are intentionally not wrapped — they
          # have plenty of subcommands that don't need the VPN (kubectx
          # config edits, `aws configure list`, etc.) and over-blocking
          # them is more annoying than helpful.
          packages = [
            (guarded {
              name = "tofu";
              realBin = "${pkgs-opentofu.opentofu}/bin/tofu";
            })
            tg-vpn-up
            tg-vpn-down
            tg-status
            pkgs.awscli2
            pkgs-kubectl.kubectl
            pkgs.eksctl
            pkgs-opentofu.opentofu
            pkgs.kubectx
            pkgs.fzf
            pkgs.networkmanager
          ];

          shellHook = ''
            ${if awsProfile == null then "unset AWS_PROFILE" else ''export AWS_PROFILE="${awsProfile}"''}

            # Directory-scoped kubectl context override. Layer a per-env
            # override file (only `current-context`) on top of ~/.kube/config
            # via KUBECONFIG so this shell defaults to its own cluster
            # without mutating the global config. Overwritten on entry so
            # the env's default really is the default; `kubectx` writes
            # land in the override file (first in KUBECONFIG) and are
            # reset on re-entry.
            CTX_FILE="$PWD/.direnv/kubeconfig-ctx"
            mkdir -p "$(dirname "$CTX_FILE")"
            cat > "$CTX_FILE" <<EOF
            apiVersion: v1
            kind: Config
            clusters: []
            contexts: []
            users: []
            current-context: ${kubeCtxArn}
            EOF
            export KUBECONFIG="$CTX_FILE:$HOME/.kube/config"

            # Entry-time warning — wrapper still blocks execution, this is
            # just so a bare `cd` (no chained command) flags the problem.
            if ! ${nmcli} -t -f NAME connection show --active 2>/dev/null | grep -qx "${vpnName}"; then
              printf '\033[1;31m!! VPN ${vpnName} is NOT active.\033[0m  Run: tg-vpn-up\n' >&2
            fi
          '';
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
            lsof
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

        # Shells for topgaming/eks — one per environment. Each pins the same
        # toolchain (aws/kubectl/tofu/eksctl) but binds an AWS profile, an
        # EKS context, and the matching OpenVPN connection together so a
        # `tofu plan` from the wrong directory can't quietly hit the wrong
        # account or run unprotected from the VPN.
        #
        # Wire them up in the eks repo with one .envrc per env:
        #   eks/dev/terraform/.envrc   →  use flake ~/nixos-config#tg-eks-dev
        #   eks/prod/terraform/.envrc  →  use flake ~/nixos-config#tg-eks-prod
        # then `direnv allow` once per directory.
        tg-eks-dev = mkEksShell {
          name = "tg-eks-dev";
          awsProfile = null; # unset = the implicit `default` profile
          vpnName = "openvpn-tg-dev";
          kubeCtxArn = "arn:aws:eks:eu-central-1:713614461671:cluster/dev-eks";
        };

        tg-eks-prod = mkEksShell {
          name = "tg-eks-prod";
          awsProfile = "tg-prod-0"; # matches `[profile tg-prod-0]` in ~/.aws/config
          vpnName = "openvpn-tg-prod";
          kubeCtxArn = "arn:aws:eks:eu-central-1:530145339946:cluster/prod-0-eks";
        };

        test-shell = pkgs.mkShell {
          packages = with pkgs; [
            cowsay
          ];
        };
      };
    };
}
