{ pkgs, ... }:

let
  # One-shot post-install setup for a fresh machine. Idempotent — safe to
  # re-run. Anything that *can* be declarative is already in the flake;
  # this script handles the few things that genuinely need a runtime side
  # effect (rustup toolchain install, kubeconfig fetch from EKS, corepack
  # shims).
  bootstrap = pkgs.writeShellApplication {
    name = "bootstrap";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      set -u
      echo "=== bootstrap: post-install setup ==="

      # 1. Sanity check — sops should have decrypted AWS creds at boot.
      if [ ! -r "$HOME/.aws/credentials" ]; then
        echo "!! ~/.aws/credentials missing — sops-nix didn't activate. Aborting."
        echo "   (Run `sudo nixos-rebuild switch` first, then re-run bootstrap.)"
        exit 1
      fi
      echo ">>> AWS creds present"

      # 2. Populate ~/.kube/config from EKS clusters.
      echo ">>> kubeconfig-refresh"
      kubeconfig-refresh || echo "!! kubeconfig-refresh failed (continuing)"

      # 3. Install the default Rust toolchain. rustup is just the manager;
      #    without `default stable`, rustc/cargo/rustfmt/clippy aren't on PATH.
      if ! rustup show active-toolchain >/dev/null 2>&1; then
        echo ">>> rustup default stable"
        rustup default stable || echo "!! rustup default stable failed (continuing)"
      else
        echo ">>> rustup toolchain already installed"
      fi

      # 4. Activate corepack shims (pnpm/yarn). Idempotent.
      echo ">>> corepack enable"
      corepack enable --install-directory "$HOME/.local/bin" 2>/dev/null \
        || corepack enable 2>/dev/null \
        || echo "!! corepack enable failed (continuing — pnpm via 'corepack pnpm' still works)"

      echo "=== bootstrap done ==="
    '';
  };
in
{
  home.packages = [ bootstrap ];
}
