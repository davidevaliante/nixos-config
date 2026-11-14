{ pkgs, lib, ... }:

let
  pname = "codegraph";
  version = "1.6.2";

  # Upstream ships a self-contained bundle: a vendored generic-Linux `node`
  # binary + the app (lib/) + a /bin/sh launcher. The vendored node can't run
  # on NixOS (no FHS loader), but the app itself is plain JS plus one N-API
  # addon (lib/kernel/codegraph-kernel.node) that only links glibc/libgcc, so
  # it loads fine into nixpkgs' node. We drop the vendored runtime and wrap
  # nixpkgs' Node 24 (same major as the bundle; node:sqlite needs >= 22.5).
  codegraph = pkgs.stdenvNoCC.mkDerivation {
    inherit pname version;

    src = pkgs.fetchurl {
      url = "https://github.com/colbymchenry/codegraph/releases/download/v${version}/codegraph-linux-x64.tar.gz";
      hash = "sha256-7wr0FgkhKPsczHI3hgALft9KaXH+YErNCL+Wbk83uCg=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    dontConfigure = true;
    dontBuild = true;
    # Leave the prebuilt addon byte-identical to upstream.
    dontStrip = true;
    dontPatchELF = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/codegraph $out/bin
      cp -r lib/. $out/lib/codegraph/

      # Flags mirror upstream's bin/codegraph launcher:
      #   --liftoff-only  avoids the V8 turboshaft WASM Zone OOM
      #   --disable-warning=ExperimentalWarning  mutes node:sqlite noise
      # The update check / `codegraph upgrade` can't work against the store,
      # and telemetry is opt-out upstream — both default off here but can
      # still be overridden from the environment.
      makeWrapper ${pkgs.nodejs_24}/bin/node $out/bin/codegraph \
        --add-flags "--liftoff-only --disable-warning=ExperimentalWarning" \
        --add-flags "$out/lib/codegraph/dist/bin/codegraph.js" \
        --set-default CODEGRAPH_NO_UPDATE_CHECK 1 \
        --set-default CODEGRAPH_TELEMETRY 0

      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      HOME=$TMPDIR $out/bin/codegraph --version | grep -qF "${version}"
    '';

    meta = {
      description = "Pre-indexed code knowledge graph for AI coding agents (MCP)";
      homepage = "https://github.com/colbymchenry/codegraph";
      license = lib.licenses.mit;
      platforms = [ "x86_64-linux" ];
      mainProgram = "codegraph";
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };

  # Same entry `codegraph install` writes for Claude Code (user scope).
  # `alwaysLoad` exempts the server from tool-search deferral so
  # codegraph_explore is available from the first prompt.
  mcpEntry = pkgs.writeText "codegraph-mcp-entry.json" (builtins.toJSON {
    type = "stdio";
    command = "codegraph";
    args = [ "serve" "--mcp" ];
    alwaysLoad = true;
  });

  # ~/.claude.json is Claude Code's own mutable state file (it rewrites it
  # constantly), so we can't own it — only upsert our one key, and only touch
  # the file when the entry actually differs so a normal activation is a no-op.
  # If the file doesn't exist yet (Claude never launched), skip; the next
  # activation picks it up.
  registerMcp = pkgs.writeShellScript "codegraph-register-mcp" ''
    set -eu
    entry="$1"
    target="$HOME/.claude.json"
    [ -f "$target" ] || exit 0
    if ${pkgs.jq}/bin/jq -e --slurpfile e "$entry" '.mcpServers.codegraph == $e[0]' "$target" >/dev/null; then
      exit 0
    fi
    ${pkgs.jq}/bin/jq --slurpfile e "$entry" '.mcpServers.codegraph = $e[0]' "$target" > "$target.tmp"
    chmod --reference="$target" "$target.tmp"
    mv "$target.tmp" "$target"
  '';
in
{
  home.packages = [ codegraph ];

  # The matching `mcp__codegraph__*` permission lives in claude-code.nix.
  home.activation.codegraphMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${registerMcp} ${mcpEntry}
  '';
}
