# Installing this config on a new host

Generic, host-agnostic runbook. Substitute `<HOSTNAME>` (e.g. `helium`) and
`<DISK_BY_ID>` (e.g. `/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7DRNJ0X123456`)
for every new machine. For sops-specific background, see `docs/sops.md`.

This flow uses [disko](https://github.com/nix-community/disko) to declare disk
layout in the flake, so partitioning is reproducible and a host can be reinstalled
by re-running the same commands. It does **not** use Calamares — see the warning
in step 11.

The install is **single-phase**: we pre-derive the new host's SSH/age keys on
an existing machine *before* walking to the new one, so secrets are already
re-encrypted to include the new host by the time the install runs. No
commented-out modules, no second rebuild after first boot.

---

## Stage 1 — Scaffold the host (on an existing machine, e.g. hydrogen)

Before walking to the new machine, add scaffolding to the repo and push.

1. **`hosts/<HOSTNAME>/disko.nix`** — disk layout. Common choices:
   - 1 GiB ESP (vfat) — fits 10+ generations of stylix-themed initrds.
   - LUKS-encrypted ext4 root.
   - Swap: zramSwap (in `default.nix`) is usually enough; add a swap partition only if you hibernate.
   - Use `device = "/dev/disk/by-id/REPLACE_ME";` as a placeholder — the runbook fills it in on the target machine.

2. **`hosts/<HOSTNAME>/default.nix`** — host module. Copy a similar host's file and adjust:
   - `networking.hostName = "<HOSTNAME>"`.
   - Imports: pick the right `modules/nixos/graphics/<intel|nvidia|amd>.nix`. Drop desktops you don't want. Include the full set of sops-dependent modules (`sops.nix`, `aws.nix`, `openvpn.nix`) — they'll work on first boot because Stage 2 below pre-derives the host key.
   - **Bootloader.** Pick one based on the dual-boot situation:
     - **systemd-boot** (default) — for single-OS hosts, or for dual-boot hosts that share an ESP with Windows (systemd-boot 252+ auto-discovers Windows Boot Manager on its own ESP).
       ```nix
       boot.loader.systemd-boot.enable = true;
       boot.loader.systemd-boot.configurationLimit = 10;
       boot.loader.efi.canTouchEfiVariables = true;
       ```
     - **GRUB + os-prober** — for dual-boot hosts where Windows lives on a *separate disk* with its own ESP. os-prober scans every mounted filesystem and adds Windows entries automatically; systemd-boot can't do this.
       ```nix
       boot.loader.systemd-boot.enable = false;
       boot.loader.efi.canTouchEfiVariables = true;
       boot.loader.efi.efiSysMountPoint = "/boot";
       boot.loader.grub = {
         enable = true;
         efiSupport = true;
         device = "nodev";
         useOSProber = true;
         configurationLimit = 10;
       };
       ```

3. **`flake.nix`** — one new line under `nixosConfigurations`:
   ```nix
   <HOSTNAME> = mkHost { hostname = "<HOSTNAME>"; };
   ```

4. **`.sops.yaml`** — add a placeholder host entry and include it in every relevant `creation_rules` block:
   ```yaml
   keys:
     - &user_davide age1...
     - &host_hydrogen age1...
     - &host_<HOSTNAME> age1REPLACE_WITH_HOST_<HOSTNAME>_PUBKEY      # NEW
   ```
   Stage 2 substitutes this token with the real pubkey.

---

## Stage 2 — Pre-derive the new host's SSH/age key (on the existing machine)

This is what makes the install single-phase. We generate the SSH host key now,
derive its age pubkey, re-encrypt every secret to include it, and carry the
key bundle on USB. The new host boots with that key already in `/etc/ssh/`,
so sops-nix activates cleanly on first boot.

5. Generate the new host's ed25519 key into a temp dir:
   ```sh
   nix-shell -p openssh ssh-to-age sops --run '
     mkdir -p /tmp/<HOSTNAME>-keys/etc/ssh
     ssh-keygen -t ed25519 -f /tmp/<HOSTNAME>-keys/etc/ssh/ssh_host_ed25519_key -N ""
     HOST_AGE=$(ssh-to-age < /tmp/<HOSTNAME>-keys/etc/ssh/ssh_host_ed25519_key.pub)
     echo "host age pubkey: $HOST_AGE"
   '
   ```
   Note the `host age pubkey` line — that's what goes into `.sops.yaml`.

6. Replace the placeholder in `.sops.yaml`:
   ```sh
   sed -i "s|age1REPLACE_WITH_HOST_<HOSTNAME>_PUBKEY|$HOST_AGE|" .sops.yaml
   git diff .sops.yaml    # sanity check
   ```

7. Re-key existing secrets so the new host is in every encryption header:
   ```sh
   nix-shell -p sops --run 'sops updatekeys -y .sops.yaml'
   ```

8. Commit + push:
   ```sh
   git add .sops.yaml secrets/
   git commit -m "feat(sops): add <HOSTNAME> host key"
   git push
   ```

9. **Stage the USB stick.** You'll need three things on the live ISO:
   - The new host's pre-generated `/etc/ssh/` directory (so sops works on first boot).
   - Your user age key (so you can author or edit secrets from the new host).
   ```sh
   cp -r /tmp/<HOSTNAME>-keys/etc /run/media/davide/<USB>/<HOSTNAME>-etc
   cp ~/.config/sops/age/keys.txt /run/media/davide/<USB>/user-keys.txt
   ```

10. Wipe the in-memory copies once they're on the USB:
    ```sh
    rm -rf /tmp/<HOSTNAME>-keys
    ```

---

## Stage 3 — Install (on the new machine)

Boot the GNOME live ISO from USB.

11. Connect to wifi (top-right network applet). Open a terminal.

12. **Identify the target disk.** If the machine has multiple drives (e.g. dual-boot with Windows on another SSD), this is the most dangerous step in the whole flow.
    ```sh
    lsblk -o NAME,SIZE,MODEL,SERIAL,TRAN
    ls -l /dev/disk/by-id/ | grep -v part
    ```
    Note the `/dev/disk/by-id/nvme-…` (or `ata-…`) of the SSD you want to install onto. **Confirm it's the empty one.**

13. **Do not open Calamares** (`Install NixOS` desktop icon). Calamares would re-partition over what disko sets up and write a generic `configuration.nix`. The whole install runs from the terminal.

14. Pull the repo onto the live ISO:
    ```sh
    nix-shell -p git
    git clone https://github.com/davidevaliante/nixos-config /tmp/nixos-config
    cd /tmp/nixos-config
    ```

15. Edit `hosts/<HOSTNAME>/disko.nix` and replace the `REPLACE_ME` device path with the by-id you noted in step 12. **Triple-check** — the next step destroys whatever's on that disk.

16. **Partition + LUKS + format + mount** with disko:
    ```sh
    sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- \
      --mode destroy,format,mount ./hosts/<HOSTNAME>/disko.nix
    ```
    Prompts for a LUKS passphrase (twice). Pick a strong one — you'll type it at every boot.

17. **Generate `hardware-configuration.nix`** for this machine. The `--no-filesystems` flag skips fileSystems / luks blocks (disko owns those); only kernel modules, microcode flag, and `hostPlatform` get written.
    ```sh
    sudo nixos-generate-config --no-filesystems --root /mnt
    sudo cp /mnt/etc/nixos/hardware-configuration.nix \
            /tmp/nixos-config/hosts/<HOSTNAME>/hardware-configuration.nix
    ```
    Replaces the committed stub.

18. **Drop the pre-generated SSH host key into place** so sops-nix can derive its age key on first boot:
    ```sh
    sudo cp -r /run/media/<your-user>/<USB>/<HOSTNAME>-etc/ssh/* /mnt/etc/ssh/
    sudo chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key
    sudo chmod 644 /mnt/etc/ssh/ssh_host_ed25519_key.pub
    sudo chown root:root /mnt/etc/ssh/ssh_host_ed25519_key*
    ```

19. **Install:**
    ```sh
    sudo nixos-install --flake /tmp/nixos-config#<HOSTNAME> --no-root-password
    ```
    Set davide's password when prompted. Activation will succeed cleanly because the host already holds an age key for every encrypted secret.

20. Unmount and reboot. Eject the USB at POST.
    ```sh
    sudo umount -R /mnt
    reboot
    ```

21. **First boot.** Type the LUKS passphrase. The bootloader (systemd-boot or GRUB) loads NixOS. On GRUB+os-prober hosts, Windows appears as its own menu entry; on systemd-boot hosts with separate-disk Windows, use the firmware boot menu (F11/F12 at POST) to switch.

22. Log in as davide. Verify secrets decrypted:
    ```sh
    ls -la ~/.ssh    # → id_ed25519, github, etc. already present
    ```

---

## Stage 4 — Optional: enable secrets-authoring on the new host

Skip this stage if the new host is read-only for secrets. Do it if you want
to `sops edit` from this machine (i.e. it'll be a daily driver where you
might add secrets in the future).

23. Restore your user age key from USB:
    ```sh
    mkdir -p ~/.config/sops/age
    cp /run/media/davide/<USB>/user-keys.txt ~/.config/sops/age/keys.txt
    chmod 600 ~/.config/sops/age/keys.txt
    ```

24. Clone the repo into your home directory:
    ```sh
    git clone git@github.com:davidevaliante/nixos-config.git ~/nixos-config
    ```

25. Commit the new `hardware-configuration.nix` (was generated in step 17 and replaced the stub):
    ```sh
    cd ~/nixos-config
    git add hosts/<HOSTNAME>/hardware-configuration.nix
    git commit -m "feat(<HOSTNAME>): add real hardware-configuration.nix"
    git push
    ```

26. On every *other* host, `git pull` so subsequent rebuilds see the re-keyed secrets.

---

## Done

The new host has full parity with the rest of the fleet: same packages, same
theming, same SSH/AWS/VPN secrets, reproducible disk layout. To reinstall
later, repeat from step 11 — the disko layout is in git, the host's age key
already exists in `.sops.yaml`, and you can re-use the same `<HOSTNAME>-etc`
USB bundle (or regenerate it from Stage 2).

## Caveats

- **Disko destroys the target disk.** There is no undo. Step 12's `lsblk` is the last line of defense.
- **Pre-generated SSH key on USB** is a private key in cleartext. Wipe it from the USB after install (`shred -u /run/media/.../ssh_host_ed25519_key`), or use a USB you destroy / encrypt afterward. Same for `user-keys.txt`.
- **Windows dual-boot bootloader choice** matters: same-ESP setups can use systemd-boot (auto-discovers Windows); separate-disk setups need GRUB+os-prober for a unified menu. See step 2.
- **os-prober occasionally misses Windows** after major Windows updates (Windows can rewrite its BCD location). Re-running `nixos-rebuild switch` re-runs os-prober and usually picks it up. If not, mount the Windows ESP read-only somewhere and inspect `\EFI\Microsoft\Boot\`.

## Why this design

The "two-phase install with commented-out modules" approach (an older revision
of this doc) is a workaround for not knowing the host's age pubkey at install
time. By pre-generating the SSH key on Stage 2 we know the pubkey upfront,
re-key all secrets to include it, and the install proceeds in one phase. This
is the standard pattern in larger sops-nix repos (see Mic92/dotfiles,
Misterio77/nix-config) and what `nixos-anywhere --extra-files` does
under the hood.
