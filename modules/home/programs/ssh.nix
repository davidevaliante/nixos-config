{ self, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
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

      # NOTE: original config had `StrictHostKeyChecking no` floating between
      # github.com and git-codecommit. In OpenSSH that line attaches to the
      # *previous* Host (github.com) — preserved here. Move to "*" if you
      # actually wanted it globally.
      "github.com" = {
        hostname = "github.com";
        user = "davide";
        identityFile = "~/.ssh/github";
        extraOptions.StrictHostKeyChecking = "no";
      };

      "git-codecommit.*.amazonaws.com" = {
        user = "APKA2MJV4RLTQ464ZMYR";
        identityFile = "~/.ssh/id_rsa";
        port = 22;
        # OpenSSH 10 warns on every connection that the session isn't using a
        # post-quantum KEX ("store now, decrypt later"). AWS CodeCommit doesn't
        # support hybrid PQ KEX yet, so the fallback is unavoidable until they
        # upgrade. Suppress the noise for this host only — auth via SSH keys is
        # unaffected; the warning is purely about session confidentiality.
        extraOptions.LogLevel = "ERROR";
      };

      "btcnode" = {
        hostname = "188.166.162.173";
        user = "root";
        identityFile = "~/.ssh/digital_ocean";
      };

      "spikeslot.com" = {
        hostname = "167.172.160.39";
        user = "root";
        identityFile = "~/.ssh/digital_ocean";
      };

      "scraper-bots" = {
        hostname = "134.209.233.135";
        user = "davide";
        identityFile = "~/.ssh/id_rsa";
      };

      "bonus-services" = {
        hostname = "142.93.172.145";
        user = "davide";
        identityFile = "~/.ssh/id_rsa";
      };

      "tg-strapi" = {
        hostname = "strapi.tgutils.com";
        user = "ubuntu";
        identityFile = "~/.ssh/tg-strapi-ec2.pem";
      };

      "cosmo-dev" = {
        hostname = "88.99.251.222";
        user = "root";
        identityFile = "~/.ssh/cosmo-dev";
      };

      "vods-prod" = {
        hostname = "ec2-18-197-17-224.eu-central-1.compute.amazonaws.com";
        user = "ubuntu";
        identityFile = "~/.ssh/vods-prod.pem";
      };
    };
  };

  # Public keys aren't sensitive — symlinked from the repo so they stay in
  # lockstep with the encrypted private halves that sops-nix drops into ~/.ssh.
  home.file.".ssh/id_ed25519.pub".source = "${self}/secrets/common/ssh-id-ed25519.pub";
  home.file.".ssh/id_rsa.pub".source     = "${self}/secrets/common/ssh-id_rsa.pub";
  home.file.".ssh/github.pub".source     = "${self}/secrets/common/ssh-github.pub";
  home.file.".ssh/cosmo-dev.pub".source  = "${self}/secrets/common/ssh-cosmo-dev.pub";
  home.file.".ssh/digital_ocean.pub".source = "${self}/secrets/common/ssh-digital_ocean.pub";
  home.file.".ssh/tg_prod_rsa.pub".source   = "${self}/secrets/common/ssh-tg_prod_rsa.pub";
}
