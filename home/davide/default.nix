{ pkgs, username, ... }:

let
  # Wrapper around `apidog` that fixes a recurring Electron bug: closing the
  # Apidog window leaves the main process and its `server.local.js` helpers
  # running, so the SingletonLock survives. Re-launching from fuzzel hands off
  # to the "existing instance" via IPC, which silently fails because the
  # window is gone — so nothing visible happens. We detect that state and
  # clean up before launching fresh.
  apidog-launch = pkgs.writeShellApplication {
    name = "apidog-launch";
    runtimeInputs = with pkgs; [ apidog jq procps coreutils ];
    text = ''
      class="Apidog"

      has_window() {
        if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
          hyprctl clients -j 2>/dev/null \
            | jq -e --arg c "$class" '.[] | select(.class == $c)' >/dev/null
        elif [ -n "''${NIRI_SOCKET:-}" ] && command -v niri >/dev/null 2>&1; then
          niri msg --json windows 2>/dev/null \
            | jq -e --arg c "$class" '.[] | select(.app_id == $c)' >/dev/null
        else
          return 1
        fi
      }

      focus_window() {
        if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
          hyprctl dispatch focuswindow "class:$class" >/dev/null || true
        elif [ -n "''${NIRI_SOCKET:-}" ] && command -v niri >/dev/null 2>&1; then
          id=$(niri msg --json windows 2>/dev/null \
            | jq -r --arg c "$class" '.[] | select(.app_id == $c) | .id' \
            | head -n1)
          [ -n "$id" ] && niri msg action focus-window --id "$id" >/dev/null || true
        fi
      }

      apidog_running() {
        pgrep -f '/apidog( |$)' >/dev/null
      }

      if has_window; then
        focus_window
        # If a URL was passed (OAuth callback, etc.), still hand it off so
        # apidog's IPC delivers it to the running instance.
        if [ $# -gt 0 ]; then
          exec apidog "$@"
        fi
        exit 0
      fi

      # No visible window. If processes are alive, the instance is stuck on a
      # stale SingletonLock — Electron caught SIGTERM and refused to die, so
      # go straight to SIGKILL. Also wipe the lock/socket files: a new apidog
      # would otherwise IPC into the dead instance via the symlinked PID.
      if apidog_running; then
        pkill -KILL -f '/apidog( |$)' || true
        for _ in $(seq 1 50); do
          apidog_running || break
          sleep 0.1
        done
      fi
      rm -f \
        "$HOME/.config/apidog/SingletonLock" \
        "$HOME/.config/apidog/SingletonSocket" \
        "$HOME/.config/apidog/SingletonCookie"

      exec apidog "$@"
    '';
  };
in
{
  imports = [
    ../../modules/home/programs/zsh.nix
    ../../modules/home/programs/starship.nix
    ../../modules/home/programs/eza.nix
    ../../modules/home/programs/zoxide.nix
    ../../modules/home/programs/bottom.nix
    ../../modules/home/programs/neovim.nix
    ../../modules/home/programs/git.nix
    ../../modules/home/programs/direnv.nix
    ../../modules/home/programs/nix-switch.nix
    ../../modules/home/programs/ssh.nix
    ../../modules/home/programs/fzf.nix
    ../../modules/home/programs/awsp.nix
    ../../modules/home/programs/kubectl.nix
    ../../modules/home/programs/opentofu.nix
    ../../modules/home/programs/kubeconfig.nix
    ../../modules/home/programs/bootstrap.nix
    ../../modules/home/programs/obs.nix
    ../../modules/home/programs/claude-code.nix
    ../../modules/home/xdg-cleanup.nix
    ../../modules/home/desktop
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.packages = (with pkgs; [
    slack
    google-chrome
    apidog
    nvd          # diff between two NixOS generations

    # Dev toolchains. nvm/fnm are intentionally excluded — they ship glibc Node
    # binaries that can't run on NixOS. Per-project version pinning is handled
    # via flake.nix + nix-direnv, not these globals.
    # Match claude-code's Node version (it ships nodejs_24 as a runtime dep);
    # mismatched majors collide on `include/node/common.gypi` in buildEnv.
    nodejs_24
    corepack_24 # activates pnpm/yarn versions pinned in package.json's packageManager field
    go
    rustup

    awscli2

    authenticator   # TOTP/HOTP codes (GNOME/libadwaita, themed via stylix)
    localsend       # cross-platform LAN file transfer with Android
  ]) ++ [ apidog-launch ];

  home.sessionVariables = {
    BROWSER = "google-chrome-stable";
    # Skip sum.golang.org for private CodeCommit repos — the public checksum DB
    # can't see them and `go get` fails with a 404. Git-side SSH rewrites for
    # this host live in modules/home/programs/git.nix.
    GOPRIVATE = "git-codecommit.eu-central-1.amazonaws.com";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";
      "x-scheme-handler/apidog" = "apidog.desktop";
      "inode/directory" = "thunar.desktop";
    };
  };

  # The apidog nixpkgs package ships the binary + icon but no .desktop
  # entry, so launchers (fuzzel, etc.) can't see it. Provide one ourselves.
  xdg.desktopEntries.apidog = {
    name = "Apidog";
    genericName = "API Client";
    comment = "All-in-one API design, test, mock and documentation platform";
    exec = "${apidog-launch}/bin/apidog-launch %U";
    icon = "apidog";
    type = "Application";
    startupNotify = true;
    categories = [ "Development" "Network" ];
    # Required for OAuth callback (apidog://...) to route from Chrome back
    # into the running Apidog instance.
    mimeType = [ "x-scheme-handler/apidog" ];
    settings.StartupWMClass = "Apidog";
  };

  mySystem.desktop.shell = "noctalia";

  programs.home-manager.enable = true;

  gtk.gtk4.theme = null;

  home.stateVersion = "25.11";
}
