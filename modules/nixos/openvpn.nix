{ pkgs, username, ... }:

{
  # `networkmanager-openvpn` lets NM understand .ovpn imports — without it
  # `nmcli connection import type openvpn ...` fails.
  environment.systemPackages = [ pkgs.networkmanager-openvpn ];
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

  # Decrypt the .ovpn files into /run/secrets/ at boot. tmpfs only — never
  # hits disk. The bootstrap script reads these and imports them into NM.
  sops.secrets."openvpn-tg-prod" = {
    format = "binary";
    sopsFile = ../../secrets/common/openvpn-tg-prod.yaml;
    path = "/run/secrets/openvpn-tg-prod.ovpn";
    owner = username;
    group = "users";
    mode = "0600";
  };

  sops.secrets."openvpn-tg-dev" = {
    format = "binary";
    sopsFile = ../../secrets/common/openvpn-tg-dev.yaml;
    path = "/run/secrets/openvpn-tg-dev.ovpn";
    owner = username;
    group = "users";
    mode = "0600";
  };
}
