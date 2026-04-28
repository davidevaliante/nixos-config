# Secrets management with sops-nix

This repo uses [sops-nix](https://github.com/Mic92/sops-nix) to encrypt secrets in
git. Every machine and every user that needs to read a secret holds an
[age](https://age-encryption.org) keypair; secrets are encrypted to all of those
public keys at once. At system activation, `sops-nix` decrypts what each host
needs and writes plaintext files into `/run/secrets/...` (or to whatever path
the consuming module asks for, e.g. `~/.ssh/id_ed25519`).

The plaintext never lands on disk outside that decryption step. The encrypted
yaml files in `secrets/` are safe to commit and push.

---

## Repo layout

```
.sops.yaml                       # creation rules: who can decrypt what
secrets/common/*.yaml            # encrypted to user + every host
secrets/hosts/<hostname>/*.yaml  # encrypted to user + that host only
modules/nixos/sops.nix           # imports sops-nix module + tools
scripts/sops-bootstrap.sh        # idempotent bootstrap helper
```

---

## First-time setup (one machine)

1. Run the helper from the repo root:

   ```sh
   bash scripts/sops-bootstrap.sh
   ```

   It will:
   - generate `~/.config/sops/age/keys.txt` (your private age key — never
     commit this)
   - derive this host's pubkey from `/etc/ssh/ssh_host_ed25519_key.pub`
   - substitute the `age1REPLACE_…` placeholders in `.sops.yaml`
   - copy the pubkeys to your Wayland clipboard

2. Review and stage the substituted `.sops.yaml`:

   ```sh
   git diff .sops.yaml
   git add .sops.yaml
   ```

3. Wire up the sops module in this host:

   ```nix
   # hosts/<hostname>/default.nix
   imports = [
     # ... existing imports ...
     ../../modules/nixos/sops.nix
   ];
   ```

4. Rebuild — at this point sops-nix is active but has no secrets to decrypt yet.

---

## Encrypting your first secret (SSH key example)

Most useful first secret on a daily-driver: your SSH private key, so it lives
encrypted in the repo and ends up at `~/.ssh/id_ed25519` on every host.

1. **Encrypt** the existing key file as binary into a sops yaml:

   ```sh
   sops --input-type binary --output-type yaml \
     -e ~/.ssh/id_ed25519 > secrets/common/ssh-id-ed25519.yaml

   # public key isn't sensitive — keep it plain
   cp ~/.ssh/id_ed25519.pub secrets/common/ssh-id-ed25519.pub
   ```

2. **Verify** it's encrypted (you should see `sops:` metadata, not the raw key):

   ```sh
   head secrets/common/ssh-id-ed25519.yaml
   ```

3. **Declare** the secret in nix so sops-nix decrypts it on activation. Add to
   `modules/nixos/sops.nix` (or a new module imported by your host):

   ```nix
   sops.secrets."ssh-id-ed25519" = {
     format = "binary";
     sopsFile = ../../secrets/common/ssh-id-ed25519.yaml;
     path = "/home/davide/.ssh/id_ed25519";
     owner = "davide";
     group = "users";
     mode = "0600";
   };
   ```

   For the public key (not encrypted), use a home-manager file or
   `home.file.".ssh/id_ed25519.pub".source = …` pointing at the `.pub` in the
   repo.

4. Rebuild. After activation, `~/.ssh/id_ed25519` exists with mode 0600.

---

## Adding a second machine

The goal: machine B can decrypt the same secrets as machine A using its own
host key + a *copy* of your user age key.

1. **Transfer your user age key** to machine B (one-time, via secure channel —
   USB stick, syncthing-private folder, scp, etc.):

   ```sh
   # on machine A
   scp ~/.config/sops/age/keys.txt machine-b:~/.config/sops/age/keys.txt
   ```

   The user pubkey is the same on both machines, so no `.sops.yaml` change is
   needed for the user.

2. **On machine B**, clone the repo and run the bootstrap helper:

   ```sh
   git clone <repo-url> ~/nixos-config
   cd ~/nixos-config
   bash scripts/sops-bootstrap.sh
   ```

   It will detect the existing user key (skip generation) and print the new
   host's pubkey.

3. **Edit `.sops.yaml`** — add an alias for the new host and include it in the
   relevant `creation_rules`:

   ```yaml
   keys:
     - &user_davide age1...
     - &host_hydrogen  age1...     # existing
     - &host_laptop age1...     # NEW

   creation_rules:
     - path_regex: secrets/common/[^/]+\.yaml$
       key_groups:
         - age:
             - *user_davide
             - *host_hydrogen
             - *host_laptop     # NEW

     - path_regex: secrets/hosts/laptop/[^/]+\.yaml$
       key_groups:
         - age:
             - *user_davide
             - *host_laptop
   ```

4. **Re-key existing secrets** so the new host can read them:

   ```sh
   sops updatekeys -y .sops.yaml
   ```

   (The bootstrap script does this automatically if encrypted secrets exist.)

5. **Enable the sops module** on the new host:

   ```nix
   # hosts/laptop/default.nix
   imports = [ ../../modules/nixos/sops.nix ];
   ```

6. Commit `.sops.yaml` + the re-keyed secrets, rebuild, done.

---

## Common operations

| Task | Command |
|---|---|
| Edit an encrypted file | `sops secrets/common/foo.yaml` |
| Decrypt to stdout | `sops -d secrets/common/foo.yaml` |
| Encrypt a file in place | `sops -e -i path/to/file` |
| Re-key after changing `.sops.yaml` | `sops updatekeys -y .sops.yaml` |
| Show this host's age pubkey | `nix-shell -p ssh-to-age --run 'ssh-to-age -i /etc/ssh/ssh_host_ed25519_key.pub'` |
| Show your user age pubkey | `age-keygen -y ~/.config/sops/age/keys.txt` |

---

## Gotchas

- **Don't commit `~/.config/sops/age/keys.txt`** — it's a private key. The path
  is outside the repo so it's safe by default; just don't move it inside.
- **Lost user age key = lost access**. Back up `keys.txt` (encrypted, e.g. on a
  hardware token or printed on paper). If you lose it, you can still recover
  *if* any other holder of `keys.txt` re-encrypts the secrets to a new pubkey,
  but it's a hassle.
- **Host re-imaged**: when a host gets reinstalled, `/etc/ssh/ssh_host_ed25519_key`
  changes → its age pubkey changes too. Re-run `scripts/sops-bootstrap.sh` and
  update the `&host_<name>` entry in `.sops.yaml`, then `sops updatekeys`.
- **Adding a new secret category** (e.g. AWS, VPN): just add another
  `creation_rules` block with the appropriate `path_regex` and the keys it
  should be encrypted to. Then `sops secrets/path/new-file.yaml` honors that
  rule automatically.
- **`sops` reads `.sops.yaml` from the working directory**: always run `sops`
  commands from the repo root.
