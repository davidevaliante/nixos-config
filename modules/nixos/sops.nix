{ inputs, pkgs, username, ... }:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];

  sops.age = {
    sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    keyFile = "/var/lib/sops-nix/key.txt";
    generateKey = true;
  };

  # Ensure ~/.ssh exists with strict perms before sops-nix drops the private
  # key into it. Without this, sops-nix would create a root-owned ~/.ssh.
  systemd.tmpfiles.rules = [
    "d /home/${username}/.ssh 0700 ${username} users -"
  ];

  sops.secrets =
    let
      sshKey = sopsRel: target: {
        format = "binary";
        sopsFile = ../.. + "/secrets/common/${sopsRel}";
        path = "/home/${username}/.ssh/${target}";
        owner = username;
        group = "users";
        mode = "0600";
      };
    in
    {
      "ssh-id-ed25519"        = sshKey "ssh-id-ed25519.yaml"        "id_ed25519";
      "ssh-id_rsa"            = sshKey "ssh-id_rsa.yaml"            "id_rsa";
      "ssh-github"            = sshKey "ssh-github.yaml"            "github";
      "ssh-cosmo-dev"         = sshKey "ssh-cosmo-dev.yaml"         "cosmo-dev";
      "ssh-digital_ocean"     = sshKey "ssh-digital_ocean.yaml"     "digital_ocean";
      "ssh-tg_prod_rsa"       = sshKey "ssh-tg_prod_rsa.yaml"       "tg_prod_rsa";
      "ssh-data-dump-runner"  = sshKey "ssh-data-dump-runner-pem.yaml" "data-dump-runner.pem";
      "ssh-tg-strapi-ec2"     = sshKey "ssh-tg-strapi-ec2-pem.yaml"    "tg-strapi-ec2.pem";
      "ssh-vods"              = sshKey "ssh-vods-pem.yaml"             "vods.pem";
      "ssh-vods-prod"         = sshKey "ssh-vods-prod-pem.yaml"        "vods-prod.pem";
    };
}
