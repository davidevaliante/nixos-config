{ self, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      addKeysToAgent = "yes";
      forwardAgent = false;
      compression = false;
      serverAliveInterval = 0;
      serverAliveCountMax = 3;
      hashKnownHosts = false;
      userKnownHostsFile = "~/.ssh/known_hosts";
      controlMaster = "no";
      controlPath = "~/.ssh/master-%r@%n:%p";
      controlPersist = "no";
    };
  };

  # Public key isn't sensitive — symlink directly from the repo so it stays
  # in lockstep with the encrypted private half (which sops-nix decrypts to
  # ~/.ssh/id_ed25519 at activation time).
  home.file.".ssh/id_ed25519.pub".source = "${self}/secrets/common/ssh-id-ed25519.pub";
}
