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
    ];
  };
in
{
  home.packages = [ pkgs.claude-code ];

  # Declarative ~/.claude/settings.json. settings.local.json (machine/session
  # writes from claude itself) is intentionally left unmanaged.
  home.file.".claude/settings.json" = {
    force = true;
    text = builtins.toJSON settings;
  };
}
