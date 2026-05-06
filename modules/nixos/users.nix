{ config, pkgs, username, ... }:

{
  # Initial user password, sops-encrypted in secrets/common/davide-password.yaml.
  # `neededForUsers` puts the decrypted file in /run/secrets-for-users/ before
  # user activation, so users.users.<name>.hashedPasswordFile can read it.
  # Change the password after first login (`passwd`) to make it a moving target.
  sops.secrets."davide-password" = {
    sopsFile = ../../secrets/common/davide-password.yaml;
    format = "binary";
    neededForUsers = true;
  };

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets."davide-password".path;
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
