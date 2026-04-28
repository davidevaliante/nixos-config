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

  sops.secrets."ssh-id-ed25519" = {
    format = "binary";
    sopsFile = ../../secrets/common/ssh-id-ed25519.yaml;
    path = "/home/${username}/.ssh/id_ed25519";
    owner = username;
    group = "users";
    mode = "0600";
  };
}
