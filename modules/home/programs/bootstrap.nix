{ pkgs, ... }:

let
  # One-shot post-install setup for a fresh machine. Idempotent — safe to
  # re-run. Anything that *can* be declarative is already in the flake;
  # this script handles the few things that genuinely need a runtime side
  # effect (rustup toolchain install, kubeconfig fetch from EKS, corepack
  # shims).
  bootstrap = pkgs.writeShellApplication {
    name = "bootstrap";
    runtimeInputs = [ pkgs.coreutils pkgs.networkmanager ];
    text = ''
      set -u
      echo "=== bootstrap: post-install setup ==="

      # 1. Sanity check — sops should have decrypted AWS creds at boot.
      if [ ! -r "$HOME/.aws/credentials" ]; then
        echo "!! ~/.aws/credentials missing — sops-nix didn't activate. Aborting."
        echo "   (Run 'sudo nixos-rebuild switch' first, then re-run bootstrap.)"
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

      # 5. Import OpenVPN profiles into NetworkManager. sops decrypts the
      #    .ovpn files into /run/secrets/ at boot; we just need to register
      #    them with NM the first time. Skip if already imported.
      echo ">>> import OpenVPN profiles"
      for ovpn in /run/secrets/openvpn-*.ovpn; do
        [ -r "$ovpn" ] || continue
        name=$(basename "$ovpn" .ovpn)   # e.g. openvpn-tg-prod
        if nmcli -t -f NAME connection show 2>/dev/null | grep -qx "$name"; then
          echo "    $name already imported"
        else
          echo "    importing $name"
          nmcli connection import type openvpn file "$ovpn" \
            || echo "    !! import of $name failed (continuing)"
          # `import` derives the connection name from the filename
          # (e.g. `openvpn-tg-prod`); that lines up with our existence
          # check above.
        fi
      done

      echo "=== bootstrap done ==="
    '';
  };
in
{
  home.packages = [ bootstrap ];
}
