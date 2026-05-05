# Installing this config on a new host

Generic, host-agnostic runbook. Substitute `<HOSTNAME>` (e.g. `helium`) and
`<DISK_BY_ID>` (e.g. `/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7DRNJ0X123456`)
for every new machine. For sops-specific background, see `docs/sops.md`.

This flow uses [disko](https://github.com/nix-community/disko) to declare disk
layout in the flake, so partitioning is reproducible and a host can be reinstalled
by re-running the same commands. It does **not** use Calamares — see the warning
in step 9.

---

## Prerequisites — scaffold the host first (on hydrogen)

Before walking to the new machine, add scaffolding to the repo and push.

1. **`hosts/<HOSTNAME>/disko.nix`** — disk layout. Common choices:
   - 1 GiB ESP (vfat) — fits 10+ generations of stylix-themed initrds.
   - LUKS-encrypted ext4 root.
   - Swap: zramSwap (in `default.nix`) is usually enough; add a swap partition only if you hibernate.
   - Use `device = "/dev/disk/by-id/REPLACE_ME";` as a placeholder — the runbook fills it in on the target machine.

2. **`hosts/<HOSTNAME>/default.nix`** — host module. Copy a similar host's file and adjust:
   - `networking.hostName = "<HOSTNAME>"`.
   - Imports: pick the right `modules/nixos/graphics/<intel|nvidia|amd>.nix`. Drop desktops you don't want.
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
   - **Do not** import `modules/nixos/sops.nix` yet — added in Phase B (a fresh host can't decrypt secrets it isn't yet a key holder for, and the activation will fail).

3. **`flake.nix`** — one new line under `nixosConfigurations`:
   ```nix
   <HOSTNAME> = mkHost { hostname = "<HOSTNAME>"; };
   ```

4. **`.sops.yaml`** — add a placeholder host entry and include it in every relevant `creation_rules` block:
   ```yaml
   keys:
     - &user_davide age1...
     - &host_hydrogen age1...
     - &host_<HOSTNAME> age1REPLACE_<HOSTNAME>      # NEW
   ```
   The `age1REPLACE_<HOSTNAME>` token is what `scripts/sops-bootstrap.sh` will substitute on first boot.

5. Commit and push.

6. **Copy your user age key to a USB stick** (or syncthing-private folder, etc.):
   ```sh
   cp ~/.config/sops/age/keys.txt /run/media/davide/<USB>/keys.txt
   ```

---

## Phase A — install (on the target machine)

Boot the GNOME live ISO from USB.

7. Connect to wifi (top-right network applet). Open a terminal.

8. **Identify the target disk.** If the machine has multiple drives (e.g. dual-boot with Windows on another SSD), this is the most dangerous step in the whole flow.
   ```sh
   lsblk -o NAME,SIZE,MODEL,SERIAL,TRAN
   ls -l /dev/disk/by-id/ | grep -v part
   ```
   Note the `/dev/disk/by-id/nvme-…` (or `ata-…`) of the SSD you want to install onto. **Confirm it's the empty one.**

9. **Do not open Calamares** (`Install NixOS` desktop icon). Calamares will re-partition over what disko set up and write a generic `configuration.nix`. The whole install runs from the terminal.

10. Pull the repo onto the live ISO:
    ```sh
    nix-shell -p git
    git clone https://github.com/davidevaliante/nixos-config /tmp/nixos-config
    cd /tmp/nixos-config
    ```

11. Edit `hosts/<HOSTNAME>/disko.nix` and replace the `REPLACE_ME` device path with the by-id you noted in step 8. **Triple-check** — the next step destroys whatever's on that disk.

12. **Partition + LUKS + format + mount** with disko:
    ```sh
    sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko -- \
      --mode destroy,format,mount ./hosts/<HOSTNAME>/disko.nix
    ```
    Prompts for a LUKS passphrase (twice). Pick a strong one — you'll type it at every boot.

13. **Generate hardware-configuration.nix** for this machine. The `--no-filesystems` flag skips fileSystems / luks blocks (disko owns those); only kernel modules, microcode flag, and `hostPlatform` get written.
    ```sh
    sudo nixos-generate-config --no-filesystems --root /mnt
    sudo cp /mnt/etc/nixos/hardware-configuration.nix \
            /tmp/nixos-config/hosts/<HOSTNAME>/hardware-configuration.nix
    ```
    Replaces the committed stub. (The stub is enough for `nix flake check` but does not match the real machine.)

14. **Install** (Phase A — no sops):
    ```sh
    sudo nixos-install --flake /tmp/nixos-config#<HOSTNAME> --no-root-password
    ```
    Set davide's password when prompted.

15. Unmount and reboot. Eject the USB at POST.
    ```sh
    sudo umount -R /mnt
    reboot
    ```

16. **First boot.** Type the LUKS passphrase. The bootloader (systemd-boot or GRUB) loads NixOS. On GRUB+os-prober hosts, Windows appears as its own menu entry; on systemd-boot hosts with separate-disk Windows, use the firmware boot menu (F11/F12 at POST) to switch.

17. Log in as davide. Connect to network.

---

## Phase B — join sops, enable secrets

18. Clone the repo into your home directory (replaces the `/tmp` copy from the live ISO):
    ```sh
    git clone https://github.com/davidevaliante/nixos-config ~/nixos-config
    cd ~/nixos-config
    ```

19. Restore your user age key from USB:
    ```sh
    mkdir -p ~/.config/sops/age
    cp /run/media/davide/<USB>/keys.txt ~/.config/sops/age/keys.txt
    chmod 600 ~/.config/sops/age/keys.txt
    ```

20. Run the bootstrap. It detects the existing user key, derives this host's age pubkey from `/etc/ssh/ssh_host_ed25519_key.pub`, and substitutes the `age1REPLACE_WITH_HOST_<HOSTNAME>_PUBKEY` placeholder in `.sops.yaml`:
    ```sh
    bash scripts/sops-bootstrap.sh
    ```

21. **Re-key** existing secrets so this host can decrypt them:
    ```sh
    nix-shell -p sops --run 'sops updatekeys -y .sops.yaml'
    ```

22. Commit + push:
    ```sh
    git add .sops.yaml secrets/
    git commit -m "feat(sops): add <HOSTNAME> host key"
    git push
    ```

23. **Commit the new `hardware-configuration.nix`** (it was generated on this host in step 13 and replaced the stub):
    ```sh
    git add hosts/<HOSTNAME>/hardware-configuration.nix
    git commit -m "feat(<HOSTNAME>): add real hardware-configuration.nix"
    git push
    ```

24. Uncomment **all three** sops-dependent imports in `hosts/<HOSTNAME>/default.nix` (the scaffolded file ships them commented out as a Phase A block):
    - `../../modules/nixos/sops.nix`
    - `../../modules/nixos/aws.nix`
    - `../../modules/nixos/openvpn.nix`

    Then rebuild:
    ```sh
    sudo nixos-rebuild switch --flake ~/nixos-config#<HOSTNAME>
    ```

25. Verify:
    ```sh
    ls -la ~/.ssh    # → id_ed25519, github, etc. should now exist
    ```

26. Commit the sops import change and push. **On every other host** (`hydrogen`, etc.), run `git pull` so they pick up the re-keyed secrets next rebuild.

---

## Done

The new host now has full parity with the rest of the fleet: same packages, same theming, same SSH/AWS/VPN secrets, reproducible disk layout. To reinstall later, repeat from step 7 — the disko layout is in git.

## Caveats

- **Two-phase sops** is unavoidable on a fresh host. The host's age pubkey is derived from its SSH host key, which doesn't exist until first boot. There's no way to encrypt secrets to a key that hasn't been generated yet.
- **Windows dual-boot bootloader choice** matters: same-ESP setups can use systemd-boot (auto-discovers Windows); separate-disk setups need GRUB+os-prober for a unified menu. See step 2.
- **os-prober occasionally misses Windows** after major Windows updates (Windows can rewrite its BCD location). Re-running `nixos-rebuild switch` re-runs os-prober and usually picks it up. If not, mount the Windows ESP read-only somewhere and inspect `\EFI\Microsoft\Boot\`.
- **Disko destroys the target disk.** There is no undo. Step 8's `lsblk` is the last line of defense.
