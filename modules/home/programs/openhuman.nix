{ pkgs, ... }:

let
  pname = "openhuman";
  version = "0.53.43";

  src = pkgs.fetchurl {
    url = "https://github.com/tinyhumansai/openhuman/releases/download/v${version}/OpenHuman_${version}_amd64.AppImage";
    hash = "sha256:15iy2syxg7dcraj90329l6akh60qgl0mm99m93xv1nlkg7pxj470";
  };

  # appimageTools.extract uses libarchive's squashfs reader, which can't read
  # the zstd-compressed squashfs this runtime ships. Fall back to the AppImage's
  # own bundled unsquashfs via `--appimage-extract`. The newer (sharun-based)
  # runtime extracts to ./AppDir with a ./squashfs-root compat symlink — move
  # the directory, not the symlink, or the store output ends up dangling.
  #
  # The bundled glibc in shared/lib is 2.35. Sharun's static-pie launcher
  # always uses bundled libc, but libs the app dlopens from the FHS overlay
  # (sqlite, libsoup_3) are built against nixpkgs glibc 2.38+ and reject the
  # old libc with `nss_error=-5925` during CEF/NSS init. Glibc is
  # backwards-compatible, so swapping the bundled core .so's for nixpkgs
  # glibc lets both bundled and FHS libs load against the same (newer) libc.
  appimageContents = pkgs.runCommand "${pname}-${version}-extracted" { inherit src; } ''
    cp $src ./app
    chmod +x ./app
    ./app --appimage-extract >/dev/null

    chmod -R u+w AppDir
    for lib in libc.so.6 libm.so.6 libdl.so.2 libpthread.so.0 librt.so.1 \
               libresolv.so.2 libutil.so.1 ld-linux-x86-64.so.2; do
      if [ -e "AppDir/shared/lib/$lib" ] && [ -e "${pkgs.glibc}/lib/$lib" ]; then
        rm -f "AppDir/shared/lib/$lib"
        cp -L "${pkgs.glibc}/lib/$lib" "AppDir/shared/lib/$lib"
      fi
    done

    mv AppDir $out
  '';

  # wrapType2 calls appimageTools.extract internally on the raw AppImage, hitting
  # the same zstd-squashfs problem. wrapAppImage takes the pre-extracted tree
  # directly and skips that step.
  #
  # OpenHuman is a Tauri-CEF app, not Tauri-webkit2gtk: it bundles libcef.so,
  # libnss3.so and a full Chromium runtime inside the AppImage, surfaced via
  # sharun. The default FHS env covers everything else it needs.
  openhuman = pkgs.appimageTools.wrapAppImage {
    inherit pname version;
    src = appimageContents;

    extraInstallCommands = ''
      install -Dm644 ${appimageContents}/OpenHuman.png \
        "$out/share/icons/hicolor/512x512/apps/openhuman.png"
    '';
  };

  # Self-healing launcher (same shape as apidog-launch). The OpenHuman main
  # process sometimes panics during CEF init but doesn't fully exit, leaving:
  #   - a "main browser" pid alive (no --type= flag) holding SingletonSocket
  #   - a fan of --type=zygote subprocesses
  #   - SingletonLock/Socket/Cookie files
  # Subsequent launches see the live socket, IPC into it via chromium's
  # singleton ("Opening in existing browser session"), and panic again —
  # fuzzel appears to do nothing. Detect the real state via the compositor
  # (only a real window counts as "alive"), and SIGKILL everything otherwise.
  openhuman-launch = pkgs.writeShellApplication {
    name = "openhuman-launch";
    runtimeInputs = with pkgs; [ openhuman procps coreutils jq ];
    text = ''
      cef_dir="$HOME/.openhuman/users/local/cef"
      # OpenHuman.desktop sets StartupWMClass=OpenHuman; niri/Hyprland report
      # it case-sensitively. Match exactly.
      class_re='^OpenHuman$'

      # CEF on Wayland with NVIDIA fails EGL context creation (EGL_BAD_ATTRIBUTE
      # loop from gl_context_egl.cc — the FHS bwrap can't reach nvidia's gbm
      # backend). Upstream's bundled .desktop forces --ozone-platform=x11 but
      # niri has no XWayland by default, so X11 fails immediately. Stay on
      # Wayland and drop hardware accel — software rendering is plenty for a
      # webview UI and avoids the entire GPU-process restart loop.
      cef_args=(
        --ozone-platform=wayland
        --disable-gpu
      )

      has_window() {
        if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
          hyprctl clients -j 2>/dev/null \
            | jq -e --arg re "$class_re" '.[] | select(.class | test($re))' >/dev/null
        elif [ -n "''${NIRI_SOCKET:-}" ] && command -v niri >/dev/null 2>&1; then
          niri msg --json windows 2>/dev/null \
            | jq -e --arg re "$class_re" '.[] | select(.app_id | test($re))' >/dev/null
        else
          return 1
        fi
      }

      openhuman_running() {
        pgrep -f 'openhuman-[^/]*-extracted/bin/OpenHuman' >/dev/null
      }

      if has_window; then
        exec openhuman "''${cef_args[@]}" "$@"
      fi

      if openhuman_running; then
        pkill -KILL -f 'openhuman-[^/]*-extracted/bin/OpenHuman' || true
        for _ in $(seq 1 50); do
          openhuman_running || break
          sleep 0.1
        done
      fi
      rm -f "$cef_dir/SingletonLock" "$cef_dir/SingletonSocket" "$cef_dir/SingletonCookie"

      exec openhuman "''${cef_args[@]}" "$@"
    '';
  };
in
{
  home.packages = [ openhuman openhuman-launch ];

  xdg.desktopEntries.openhuman = {
    name = "OpenHuman";
    genericName = "AI Assistant";
    comment = "Local-first AI agent with memory";
    exec = "openhuman-launch %U";
    icon = "openhuman";
    type = "Application";
    startupNotify = true;
    categories = [ "Utility" "Office" ];
    # Required for the openhuman:// OAuth callback to route from Chrome back
    # into the running app (matches the upstream AppImage's bundled .desktop).
    mimeType = [ "x-scheme-handler/openhuman" ];
  };

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/openhuman" = "openhuman.desktop";
  };

  # OpenHuman's `cef-prewarm` spawns a "hidden warmup webview" (src/lib.rs:1066)
  # as a startup-perf hack. Under Wayland, CEF can't hide a top-level surface,
  # so niri renders it as an empty window alongside the real OpenHuman one.
  # CEF on Ozone-Wayland ignores --class/--name, so we can't tag it with an
  # app-id — match the empty/empty signature and shove it 1×1 offscreen.
  programs.niri.settings.window-rules = [
    {
      matches = [ { app-id = "^$"; title = "^$"; } ];
      open-floating = true;
      open-focused = false;
      min-width = 1;
      max-width = 1;
      min-height = 1;
      max-height = 1;
      default-floating-position = { x = 9000; y = 9000; relative-to = "top-left"; };
    }
  ];
}
