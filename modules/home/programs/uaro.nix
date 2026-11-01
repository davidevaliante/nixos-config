{ config, pkgs, lib, ... }:

let
  home = config.home.homeDirectory;

  gameDir =
    "${home}/Games/uaro-2/drive_c/users/steamuser/AppData/Local/Programs/UaRO World of Your Dream";

  # ---------------------------------------------------------------------------
  # Spoofed hardware identity fed to Gepard Shield.
  #
  # Gepard runs as a usermode Windows process under Proton/Wine, so every HWID it
  # reads resolves one layer down to something *Wine* sourced from Linux. We
  # control each source at that Linux layer — never "in Windows":
  #
  #   MachineGuid  <- prefix registry (system.reg)            -> file edit
  #   C: serial    <- prefix drive file (.windows-serial)     -> file write
  #   ComputerName <- host gethostname()                      -> UTS namespace
  #   SMBIOS/DMI   <- host /sys/class/dmi/id/*                -> mount namespace
  #
  # Still leaking (documented, not yet spoofed):
  #   MAC address  <- host netlink (GetAdaptersAddresses). Needs a net namespace
  #                   + veth/NAT to isolate; deferred to modules/nixos/.
  #   raw CPUID    <- the `cpuid` instruction. Not forgeable in usermode without
  #                   a hypervisor (which Gepard also detects). Unspoofable here.
  #
  # Edit any value below freely — they are arbitrary but kept internally coherent
  # (a plausible MSI B550 box rather than this host's ASUS board).
  # ---------------------------------------------------------------------------
  machineGuid = "f4663877-aaab-410d-a970-c0907bd50dc5";
  volumeSerial = "33CAFACC"; # C: volume serial, 8 hex digits uppercase
  hostName = "DESKTOP-7KX2P4Q";

  # Fake SMBIOS/DMI. Wine builds GetSystemFirmwareTable('RSMB') and the WMI
  # Win32_* classes (ComputerSystemProduct.UUID, BaseBoard.SerialNumber, BIOS,
  # ...) from these exact sysfs filenames. On this host the strongest fields
  # (product_uuid, *_serial) are root-only 0400, so Wine currently reads them
  # EMPTY; bind-mounting world-readable fakes turns those blanks into a
  # deterministic identity we control.
  dmi = {
    sys_vendor = "Micro-Star International Co., Ltd.";
    product_name = "MS-7C56";
    product_version = "1.0";
    product_serial = "J1800123456789";
    product_uuid = "b58e889c-3d6f-4a1e-9c2f-1a2b3c4d5e6f";
    board_vendor = "Micro-Star International Co., Ltd.";
    board_name = "B550M PRO-VDH WIFI (MS-7C95)";
    board_version = "1.0";
    board_serial = "K1900987654321";
    chassis_vendor = "Micro-Star International Co., Ltd.";
    chassis_serial = "To Be Filled By O.E.M.";
    bios_vendor = "American Megatrends International, LLC.";
    bios_version = "H.A0";
    bios_date = "05/18/2023";
  };

  dmiFields = builtins.attrNames dmi;

  # Immutable store dir holding one file per DMI field; used as bind sources.
  # Trailing newline matches the sysfs convention Wine's parser expects.
  dmiDir = pkgs.runCommand "uaro-fake-dmi" { } (''
    mkdir -p "$out"
  '' + lib.concatMapStrings (k: ''
    printf '%s\n' ${lib.escapeShellArg dmi.${k}} > "$out/${k}"
  '') dmiFields);

  unshareBin = "${pkgs.util-linux}/bin/unshare";
  mountBin = "${pkgs.util-linux}/bin/mount";
  hostnameBin = "${pkgs.nettools}/bin/hostname";

  # Applied inside the namespace (needs the namespace's CAP_SYS_ADMIN). Kept as
  # a snippet so the probe can run the identical setup.
  spoofSetup = ''
    if [ -z "''${UARO_NO_HOSTNAME:-}" ]; then
      ${hostnameBin} "${hostName}"
    fi
    if [ -z "''${UARO_NO_DMI:-}" ]; then
      for f in ${lib.concatStringsSep " " dmiFields}; do
        if [ -e "/sys/class/dmi/id/$f" ]; then
          ${mountBin} --bind "${dmiDir}/$f" "/sys/class/dmi/id/$f"
        fi
      done
    fi
  '';

  # Stage 2: runs as a NON-root uid (umu/pressure-vessel refuse euid 0) that still
  # resolves to the real user, so the prefix under ~/Games stays accessible.
  # steam-run's own bubblewrap then recursively binds /sys (`--bind /sys /sys`),
  # carrying our fake DMI submounts through to Wine.
  gameLauncher = pkgs.writeShellScript "uaro-game" ''
    set -euo pipefail
    cd "${gameDir}"
    exec ${pkgs.steam-run}/bin/steam-run \
      "${home}/.local/share/lutris/runtime/umu/umu-run" \
      "${gameDir}/UaRo Patcher.exe" "$@"
  '';

  # Stage 1: first process of a fresh user+mount+uts namespace. --map-root-user
  # maps our real uid -> in-ns 0 so caps survive this exec (a non-root euid would
  # drop them, breaking mount/hostname). We do the spoof setup here while root,
  # then drop into a nested user namespace mapping in-ns 1000 -> outer 0 -> real
  # uid: the game sees a non-root uid (keeps umu happy) yet the kernel still
  # resolves its file access to the real user, and it inherits the mount+uts
  # namespaces (fake DMI + hostname) from this stage.
  innerLauncher = pkgs.writeShellScript "uaro-setup" ''
    set -euo pipefail
    ${spoofSetup}
    exec ${unshareBin} --user \
      --map-users "''${UARO_UID}:0:1" --map-groups "''${UARO_GID}:0:1" -- \
      ${gameLauncher} "$@"
  '';

  # See hosts/helium notes + git history for why this is a bespoke umu-run wrapper
  # rather than a Lutris game entry. System-side Wine/Lutris live in
  # modules/nixos/lutris.nix; the Wine prefix itself stays outside Nix.
  uaro = pkgs.writeShellScriptBin "uaro" ''
    set -euo pipefail
    export WINEPREFIX="${home}/Games/uaro-2"
    export GAMEID="umu-0"
    export STORE="none"

    # Prefix-local spoofs (no namespace needed): patched offline before umu-run
    # starts a wineserver, so the game reads the pinned values. Idempotent.
    if [ -f "$WINEPREFIX/system.reg" ]; then
      sed -i -E \
        -e 's|^"MachineGuid"=".*"|"MachineGuid"="${machineGuid}"|' \
        "$WINEPREFIX/system.reg"
    fi
    printf '%s' "${volumeSerial}" > "$WINEPREFIX/drive_c/.windows-serial"

    # Pin to GE-Proton (declared via proton-ge-bin in modules/nixos/steam.nix).
    # Resolve by glob so a version bump (GE-Proton11-1 -> 11-2) doesn't break it.
    PROTONPATH="$(ls -d "${home}"/.local/share/Steam/compatibilitytools.d/GE-Proton* 2>/dev/null | sort -V | tail -1 || true)"
    if [ -z "''${PROTONPATH}" ]; then
      echo "uaro: no GE-Proton under ~/.local/share/Steam/compatibilitytools.d — is Steam running with proton-ge-bin?" >&2
      exit 1
    fi
    export PROTONPATH

    # Debug/bisection knobs (set in the shell before `uaro`):
    #   UARO_NO_SPOOF=1     launch exactly like the old version (no namespace)
    #   UARO_NO_DMI=1       namespace + hostname, but skip the SMBIOS binds
    #   UARO_NO_HOSTNAME=1  namespace + SMBIOS, but keep the real hostname
    if [ -n "''${UARO_NO_SPOOF:-}" ]; then
      echo "uaro: UARO_NO_SPOOF set — launching WITHOUT namespace/spoof (baseline)" >&2
      exec ${gameLauncher} "$@"
    fi

    # Capture the real uid/gid so stage 1 can map a non-root uid back to us.
    UARO_UID="$(id -u)"; UARO_GID="$(id -g)"; export UARO_UID UARO_GID

    # Host-identity spoofs (hostname + SMBIOS) happen inside the namespace.
    exec ${unshareBin} --user --map-root-user --mount --uts -- \
      ${innerLauncher} "$@"
  '';

  # Verification helper: dumps the HWID surface as the host sees it, then as the
  # uaro namespace exposes it (== what Wine/Gepard read). Run it to confirm each
  # spoof lands before trusting the launcher.
  dumpSnippet = ''
    echo "  hostname        = $(${hostnameBin})"
    for f in ${lib.concatStringsSep " " dmiFields}; do
      printf '  dmi/%-15s = %s\n' "$f" "$(cat "/sys/class/dmi/id/$f" 2>/dev/null || echo '<unreadable/empty>')"
    done
    echo "  MACs (NOT spoofed — still host):"
    for i in /sys/class/net/*; do
      n="''${i##*/}"
      [ "$n" = lo ] && continue
      printf '    %-16s %s\n' "$n" "$(cat "$i/address" 2>/dev/null)"
    done
  '';

  # Stage 2 of the probe: dumps from the same non-root uid the game runs as.
  probeDump = pkgs.writeShellScript "uaro-probe-dump" ''
    echo "  (running as uid $(id -u))"
    ${dumpSnippet}
  '';

  probeInner = pkgs.writeShellScript "uaro-probe-inner" ''
    ${spoofSetup}
    exec ${unshareBin} --user \
      --map-users "''${UARO_UID}:0:1" --map-groups "''${UARO_GID}:0:1" -- \
      ${probeDump}
  '';

  probe = pkgs.writeShellScriptBin "uaro-hwid-probe" ''
    set -uo pipefail
    echo "=== HOST view (real hardware, leaks without the wrapper) ==="
    ${dumpSnippet}
    echo
    echo "=== uaro namespace view (what Wine/Gepard read with the wrapper) ==="
    UARO_UID="$(id -u)"; UARO_GID="$(id -g)"; export UARO_UID UARO_GID
    ${unshareBin} --user --map-root-user --mount --uts -- ${probeInner}
    echo
    echo "For the Windows-visible confirmation, launch the prefix and query:"
    echo "  wine reg query 'HKLM\\SOFTWARE\\Microsoft\\Cryptography' /v MachineGuid"
    echo "  wine cmd /c vol C:"
    echo "  wine wmic path Win32_ComputerSystemProduct get UUID,IdentifyingNumber"
    echo "  wine wmic path Win32_BaseBoard get SerialNumber"
    echo "  wine wmic nicconfig get MACAddress   # expect host MAC (not yet spoofed)"
  '';
in
{
  # `uaro` on PATH for terminal launches, `uaro-hwid-probe` to verify the spoof,
  # plus a menu entry for fuzzel/GNOME.
  home.packages = [ uaro probe ];

  xdg.desktopEntries.uaro = {
    name = "UaRO World of Your Dream";
    genericName = "Ragnarok Online";
    comment = "Ragnarok Online private server (Proton/umu)";
    exec = "${uaro}/bin/uaro";
    icon = "applications-games";
    type = "Application";
    terminal = false;
    categories = [ "Game" "RolePlaying" ];
    # Proton reports this app_id under Wayland; match it so the compositor links
    # the startup notification to the game window.
    settings.StartupWMClass = "uaro patcher.exe";
  };
}
