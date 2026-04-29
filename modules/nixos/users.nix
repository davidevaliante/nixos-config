{ pkgs, username, ... }:

{
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # Skip the password prompt for `nixos-rebuild` only — the rest of sudo still
  # asks. `/run/current-system/sw/bin/...` resolves to whichever rebuild binary
  # the active generation ships, so this stays valid across upgrades.
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
