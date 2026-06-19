{ pkgs, lib, ... }:

let
  settings = {
    # Baseline of plugins we want guaranteed on. `/plugin install` may add more
    # at runtime (written into the mutable settings.json — see the activation
    # merge below); those survive rebuilds, while these stay enforced.
    enabledPlugins = {
      "lua-lsp@claude-plugins-official" = true;
      "typescript-lsp@claude-plugins-official" = true;
      "gopls-lsp@claude-plugins-official" = true;
    };

    permissions.allow = [
      "Bash(nix flake check *)"
      "Bash(nix eval *)"
      "Bash(nix-instantiate *)"
      "Bash(nix flake metadata *)"
      "Bash(nix-store -q *)"
      "Bash(noctalia-shell ipc show *)"
      "Bash(sops --decrypt *)"
      "Bash(sops -d *)"
      "Bash(bluetoothctl devices *)"
      "Bash(git *)"
      "Bash(npm *)"
      "Bash(air *)"
      "Bash(ls*)"
      "Read"
    ];

    permissions.deny = [
      "Bash(git push *)"
    ];

    statusLine = {
      type = "command";
      command = "bash /home/davide/.claude/statusline-command.sh";
    };

    attribution = {
      commit = "";
      pr = "";
    };
  };

  # JSON base that Nix is authoritative for. Generated into the store, then
  # deep-merged over the live (writable) settings.json on every activation.
  settingsBase = pkgs.writeText "claude-settings-base.json" (builtins.toJSON settings);

  # Deep-merge: `jq '.[0] * .[1]'` recursively merges objects and lets the
  # right-hand side (our Nix base) win on conflicts, while keys that only exist
  # on the left (e.g. plugins added via `/plugin`) are preserved. enabledPlugins
  # is an object, so Nix-declared and Claude-added entries are unioned.
  mergeSettings = pkgs.writeShellScript "claude-settings-merge" ''
    set -eu
    base="$1"
    target="$HOME/.claude/settings.json"
    mkdir -p "$(dirname "$target")"
    if [ -L "$target" ] || [ ! -e "$target" ]; then
      # Fresh, or a leftover read-only store symlink: seed a real mutable file.
      rm -f "$target"
      cp "$base" "$target"
    else
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$target" "$base" > "$target.tmp"
      mv "$target.tmp" "$target"
    fi
    chmod u+w "$target"
  '';

  statuslineScript = ''
    #!/usr/bin/env bash
    # Claude Code statusLine — shows directory, git branch, context usage, model.
    # Palette uses standard ANSI colors; the terminal renders them dimmed per the
    # statusLine spec. Colors mirror the Oxocarbon/starship theme in use.

    input=$(cat)

    # ── directory ──────────────────────────────────────────────────────────────
    cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
    project_dir=$(echo "$input" | jq -r '.workspace.project_dir // ""')

    # Compute display path: strip project root prefix, then keep at most 3
    # trailing components (mirrors starship directory defaults).
    if [ -n "$project_dir" ] && [ "$project_dir" != "null" ] && [[ "$cwd" == "$project_dir"* ]]; then
      rel="''${cwd#"$project_dir"}"
      rel="''${rel#/}"
      repo_name=$(basename "$project_dir")
      if [ -z "$rel" ]; then
        display_path="$repo_name"
      else
        IFS='/' read -ra parts <<< "$rel"
        nparts=''${#parts[@]}
        if [ "$nparts" -le 3 ]; then
          display_path="$repo_name/$rel"
        else
          display_path="…/''${parts[$nparts-3]}/''${parts[$nparts-2]}/''${parts[$nparts-1]}"
        fi
      fi
    else
      IFS='/' read -ra parts <<< "''${cwd#/}"
      nparts=''${#parts[@]}
      if [ "$nparts" -le 3 ]; then
        display_path="$cwd"
      else
        display_path="…/''${parts[$nparts-3]}/''${parts[$nparts-2]}/''${parts[$nparts-1]}"
      fi
    fi

    # ── git branch ─────────────────────────────────────────────────────────────
    branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || true)

    # ── context window ─────────────────────────────────────────────────────────
    used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

    # ── model ──────────────────────────────────────────────────────────────────
    model=$(echo "$input" | jq -r '.model.display_name // ""')

    # ── assemble ───────────────────────────────────────────────────────────────
    RESET='\033[0m'
    BOLD='\033[1m'
    CYAN='\033[36m'    # directory
    MAGENTA='\033[35m' # git branch (matches starship git_branch default)
    YELLOW='\033[33m'  # context usage warning colour
    DIM='\033[2m'      # model name (secondary info)

    out=""

    out+="$(printf "''${BOLD}''${CYAN}%s''${RESET}" "$display_path")"

    if [ -n "$branch" ]; then
      out+=" $(printf "''${MAGENTA} %s''${RESET}" "$branch")"
    fi

    if [ -n "$used_pct" ]; then
      used_int=$(printf '%.0f' "$used_pct")
      out+=" $(printf "''${YELLOW}ctx:''${used_int}%%''${RESET}")"
    fi

    if [ -n "$model" ] && [ "$model" != "null" ]; then
      out+=" $(printf "''${DIM}%s''${RESET}" "$model")"
    fi

    printf "%s" "$out"
  '';
in
{
  home.packages = [ pkgs.claude-code ];

  # ~/.claude/settings.json is kept WRITABLE (not a store symlink) so the
  # `/plugin` UI can persist enabledPlugins itself — a store symlink makes those
  # writes fail with EROFS. On each activation we deep-merge our Nix base over
  # the live file: Nix-owned keys (permissions, statusLine, attribution) stay
  # authoritative, Claude-owned keys (plugins) survive. settings.local.json is
  # left fully unmanaged.
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${mergeSettings} ${settingsBase}
  '';

  # Status line helper script — referenced by settings.json above.
  home.file.".claude/statusline-command.sh" = {
    force = true;
    executable = true;
    text = statuslineScript;
  };
}
