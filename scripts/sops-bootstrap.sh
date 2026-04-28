#!/usr/bin/env bash
# sops-nix bootstrap helper.
# Idempotent — safe to run on first machine, additional machines, or repeatedly.
#
# What it does:
#   - Generates a user age key at ~/.config/sops/age/keys.txt if missing
#   - Derives this host's age pubkey from /etc/ssh/ssh_host_ed25519_key.pub
#   - Substitutes age1REPLACE_… placeholders in .sops.yaml (first machine only)
#   - Prints next steps + copies pubkeys to clipboard if wl-copy is available
#
# It does NOT:
#   - Append a new host to .sops.yaml — that's a manual, one-line edit
#   - Encrypt any files — see docs/sops.md for examples

set -euo pipefail

# Auto-bootstrap deps via nix-shell if missing
if ! command -v age-keygen >/dev/null || ! command -v ssh-to-age >/dev/null || ! command -v sops >/dev/null; then
  if command -v nix-shell >/dev/null; then
    exec nix-shell -p age ssh-to-age sops --command "bash $0 $*"
  fi
  echo "missing one of: age, ssh-to-age, sops — and no nix-shell to bootstrap with" >&2
  exit 1
fi

REPO="${SOPS_BOOTSTRAP_REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
USER_AGE_KEY="$HOME/.config/sops/age/keys.txt"
SOPS_YAML="$REPO/.sops.yaml"
HOST="$(cat /etc/hostname | tr -d '[:space:]')"
SSH_HOST_PUBKEY="/etc/ssh/ssh_host_ed25519_key.pub"

bold()   { printf '\033[1m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
cyan()   { printf '\033[36m%s\033[0m\n' "$*"; }

bold "═══ sops-nix bootstrap ═══"
echo "  repo : $REPO"
echo "  host : $HOST"
echo

# 1. User age key
if [ ! -f "$USER_AGE_KEY" ]; then
  yellow "→ generating user age key at $USER_AGE_KEY"
  mkdir -p "$(dirname "$USER_AGE_KEY")"
  age-keygen -o "$USER_AGE_KEY"
  chmod 600 "$USER_AGE_KEY"
  green "  done"
else
  cyan "✓ user age key already exists"
fi

USER_PUBKEY="$(age-keygen -y "$USER_AGE_KEY")"
echo "  user pubkey : $USER_PUBKEY"

# 2. Host age pubkey from SSH host key
if [ ! -r "$SSH_HOST_PUBKEY" ]; then
  echo
  yellow "! cannot read $SSH_HOST_PUBKEY — is OpenSSH installed and the host key generated?"
  exit 1
fi

HOST_PUBKEY="$(ssh-to-age -i "$SSH_HOST_PUBKEY")"
echo "  host pubkey : $HOST_PUBKEY"
echo

# 3. .sops.yaml placeholder substitution (first-machine only)
if [ ! -f "$SOPS_YAML" ]; then
  yellow "! $SOPS_YAML does not exist — skipping placeholder substitution"
elif grep -q 'age1REPLACE_WITH_USER_PUBKEY\|age1REPLACE_WITH_HOST' "$SOPS_YAML"; then
  yellow "→ substituting placeholders in $SOPS_YAML"
  sed -i \
    -e "s|age1REPLACE_WITH_USER_PUBKEY|$USER_PUBKEY|g" \
    -e "s|age1REPLACE_WITH_HOST_${HOST}_PUBKEY|$HOST_PUBKEY|g" \
    -e "s|age1REPLACE_WITH_HOST_NIXOS_PUBKEY|$HOST_PUBKEY|g" \
    "$SOPS_YAML"
  green "  done"
else
  cyan "✓ no placeholders in $SOPS_YAML"
fi

# 4. Re-key existing secrets if any
if compgen -G "$REPO/secrets/**/*.yaml" >/dev/null 2>&1; then
  ANY=$(find "$REPO/secrets" -type f -name '*.yaml' -size +0 2>/dev/null | head -1)
  if [ -n "$ANY" ]; then
    yellow "→ found existing encrypted secrets — re-keying with current .sops.yaml"
    (cd "$REPO" && sops updatekeys -y .sops.yaml || true)
  fi
fi

# 5. Clipboard convenience
if command -v wl-copy >/dev/null 2>&1; then
  printf 'user: %s\nhost (%s): %s\n' "$USER_PUBKEY" "$HOST" "$HOST_PUBKEY" | wl-copy
  cyan "✓ pubkeys copied to clipboard"
fi

echo
bold "═══ next steps ═══"
cat <<EOF

  • If this is the FIRST machine:
      git -C "$REPO" diff .sops.yaml      # review the substitution
      git -C "$REPO" add .sops.yaml
      $(cyan "→ see docs/sops.md → 'Encrypting your first secret'")

  • If this is an ADDITIONAL machine:
      Edit $SOPS_YAML and add this host's pubkey + creation_rule for it:

          - &host_${HOST} ${HOST_PUBKEY}

      Then under creation_rules add a path_regex block referencing &host_${HOST}.
      Finally re-run this script so 'sops updatekeys' includes the new key
      in every encrypted file.

  • Then enable the sops module on this host:
      Add ../../modules/nixos/sops.nix to imports in hosts/$HOST/default.nix

EOF
