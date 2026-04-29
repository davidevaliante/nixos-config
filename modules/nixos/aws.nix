{ username, ... }:

{
  # Ensure ~/.aws exists with strict perms before sops-nix drops the
  # decrypted credentials/config files into it. Without this, sops-nix would
  # create a root-owned ~/.aws.
  systemd.tmpfiles.rules = [
    "d /home/${username}/.aws 0700 ${username} users -"
  ];

  sops.secrets."aws-credentials" = {
    format = "binary";
    sopsFile = ../../secrets/common/aws-credentials.yaml;
    path = "/home/${username}/.aws/credentials";
    owner = username;
    group = "users";
    mode = "0600";
  };

  sops.secrets."aws-config" = {
    format = "binary";
    sopsFile = ../../secrets/common/aws-config.yaml;
    path = "/home/${username}/.aws/config";
    owner = username;
    group = "users";
    mode = "0600";
  };
}
