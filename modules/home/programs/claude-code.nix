{ pkgs, ... }:

let
  settings = {
    enabledPlugins = {
      "lua-lsp@claude-plugins-official" = true;
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

  # Declarative ~/.claude/settings.json. settings.local.json (machine/session
  # writes from claude itself) is intentionally left unmanaged.
  home.file.".claude/settings.json" = {
    force = true;
    text = builtins.toJSON settings;
  };

  # Status line helper script — referenced by settings.json above.
  home.file.".claude/statusline-command.sh" = {
    force = true;
    executable = true;
    text = statuslineScript;
  };
}
