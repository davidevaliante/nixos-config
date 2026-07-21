{ config, pkgs, ... }:

let
  home = config.home.homeDirectory;

  # UaRO was installed into a standalone Proton prefix (~/Games/uaro, under
  # drive_c/users/steamuser) rather than as a Lutris library game, so no Lutris
  # DB entry exists to launch it — the app-menu shortcut disappeared with it.
  # This wrapper reproduces the launch via Lutris's bundled umu-run +
  # Proton-Experimental, independent of any Lutris game entry. The Wine *prefix*
  # itself is mutable game data and stays outside Nix; only the launcher is
  # declared here. System-side Wine/Lutris live in modules/nixos/lutris.nix.
  #
  # umu-run shells out to Valve's pressure-vessel/steam-runtime, which are
  # generic dynamically-linked ELF binaries NixOS can't exec directly (no
  # /lib64/ld-linux). Lutris hides this by running games inside its own FHS
  # sandbox; launching bare umu-run does not, and dies at pressure-vessel-wrap.
  # steam-run (from programs.steam) provides the FHS env that lets the runtime
  # bootstrap — verified to launch the patcher cleanly.
  uaro = pkgs.writeShellScriptBin "uaro" ''
    set -euo pipefail
    export WINEPREFIX="${home}/Games/uaro"
    export GAMEID="umu-0"
    export STORE="none"

    # Pin to GE-Proton (declared via proton-ge-bin in modules/nixos/steam.nix) —
    # it's the runtime the prefix was created with, and the only Proton
    # guaranteed to exist on a fresh daily driver ("Proton - Experimental" is an
    # undeclared Steam artifact). Resolve by glob so a proton-ge-bin version bump
    # (GE-Proton11-1 -> 11-2 -> ...) doesn't break a hardcoded path.
    PROTONPATH="$(ls -d "${home}"/.local/share/Steam/compatibilitytools.d/GE-Proton* 2>/dev/null | sort -V | tail -1 || true)"
    if [ -z "''${PROTONPATH}" ]; then
      echo "uaro: no GE-Proton under ~/.local/share/Steam/compatibilitytools.d — is Steam running with proton-ge-bin?" >&2
      exit 1
    fi
    export PROTONPATH

    # The patcher opens main.inf / Patch.inf / data.grf by *relative* path, so it
    # must run from its own directory. Proton derives the Windows CWD from the
    # Linux CWD, so cd there before launching (mirrors the original shortcut's
    # Path=). Without this it fails with "failed to open main.inf".
    GAMEDIR="${home}/Games/uaro/drive_c/users/steamuser/AppData/Local/Programs/UaRO World of Your Dream"
    cd "$GAMEDIR"

    exec ${pkgs.steam-run}/bin/steam-run \
      "${home}/.local/share/lutris/runtime/umu/umu-run" \
      "$GAMEDIR/UaRo Patcher.exe" "$@"
  '';
in
{
  # `uaro` on PATH for terminal launches, plus a menu entry for fuzzel/GNOME.
  home.packages = [ uaro ];

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
