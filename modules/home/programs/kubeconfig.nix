{ pkgs, lib, ... }:

let
  region = "eu-central-1";
  clusters = [
    { name = "dev-eks";    profile = "default"; }
    { name = "prod-0-eks"; profile = "tg-prod-0"; }
  ];

  # Idempotent: `aws eks update-kubeconfig` merges entries into
  # ~/.kube/config, re-running just refreshes them. Each cluster runs in
  # its own block so a failure for one (e.g., expired creds for that
  # profile) doesn't skip the others.
  refreshScript = pkgs.writeShellApplication {
    name = "kubeconfig-refresh";
    runtimeInputs = [ pkgs.awscli2 ];
    text = lib.concatMapStringsSep "\n" (c: ''
      echo ">>> ${c.name} (profile=${c.profile})"
      aws eks update-kubeconfig \
        --region ${region} \
        --name ${c.name} \
        --profile ${c.profile} \
        || echo "!! ${c.name} update failed (continuing)"
    '') clusters;
  };
in
{
  home.packages = [
    refreshScript
    pkgs.kubectx # ships kubectx + kubens for fzf-style context/namespace switching
  ];
}
