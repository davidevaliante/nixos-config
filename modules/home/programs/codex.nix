{ pkgs, ... }:

{
  # OpenAI Codex CLI — lightweight terminal coding agent. Config lives in the
  # writable ~/.codex/ (auth tokens, config.toml), so it's left unmanaged here;
  # we only guarantee the binary is on PATH, mirroring claude-code.nix.
  home.packages = [ pkgs.codex ];
}
