{ self, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        ForwardAgent = false;
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };

      # NOTE: original config had `StrictHostKeyChecking no` floating between
      # github.com and git-codecommit. In OpenSSH that line attaches to the
      # *previous* Host (github.com) — preserved here. Move to "*" if you
      # actually wanted it globally.
      "github.com" = {
        HostName = "github.com";
        User = "davide";
        IdentityFile = "~/.ssh/github";
        StrictHostKeyChecking = "no";
      };

      "git-codecommit.*.amazonaws.com" = {
        User = "APKA2MJV4RLTQ464ZMYR";
        IdentityFile = "~/.ssh/id_rsa";
        Port = 22;
        # OpenSSH 10 warns on every connection that the session isn't using a
        # post-quantum KEX ("store now, decrypt later"). AWS CodeCommit doesn't
        # support hybrid PQ KEX yet, so the fallback is unavoidable until they
        # upgrade. Suppress the noise for this host only — auth via SSH keys is
        # unaffected; the warning is purely about session confidentiality.
        LogLevel = "ERROR";
      };

      "btcnode" = {
        HostName = "188.166.162.173";
        User = "root";
        IdentityFile = "~/.ssh/digital_ocean";
      };

      "spikeslot.com" = {
        HostName = "167.172.160.39";
        User = "root";
        IdentityFile = "~/.ssh/digital_ocean";
      };

      "scraper-bots" = {
        HostName = "134.209.233.135";
        User = "davide";
        IdentityFile = "~/.ssh/id_rsa";
      };

      "bonus-services" = {
        HostName = "142.93.172.145";
        User = "davide";
        IdentityFile = "~/.ssh/id_rsa";
      };

      "tg-strapi" = {
        HostName = "strapi.tgutils.com";
        User = "ubuntu";
        IdentityFile = "~/.ssh/tg-strapi-ec2.pem";
      };

      "cosmo-dev" = {
        HostName = "88.99.251.222";
        User = "root";
        IdentityFile = "~/.ssh/cosmo-dev";
      };

      "vods-prod" = {
        HostName = "ec2-18-197-17-224.eu-central-1.compute.amazonaws.com";
        User = "ubuntu";
        IdentityFile = "~/.ssh/vods-prod.pem";
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
