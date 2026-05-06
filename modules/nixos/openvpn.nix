{ pkgs, username, ... }:

let
  profiles = [ "openvpn-tg-prod" "openvpn-tg-dev" ];
in
{
  # `networkmanager-openvpn` lets NM understand .ovpn imports — without it
  # `nmcli connection import type openvpn ...` fails.
  environment.systemPackages = [ pkgs.networkmanager-openvpn ];
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

  # Decrypt the .ovpn files into /run/secrets/ at boot. tmpfs only — never
  # hits disk. The systemd unit below registers them with NetworkManager
  # idempotently on every activation, so a fresh host gets the VPN entries
  # without needing to run `bootstrap` manually.
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

  # Idempotent OVPN→NM import. Runs after NetworkManager is up; safe on
  # every boot because each profile is a no-op if already registered.
  # Imports as system-wide connections (visible to every user's tray).
  systemd.services.openvpn-nm-import = {
    description = "Import OpenVPN profiles (sops) into NetworkManager";
    after  = [ "NetworkManager.service" ];
    wants  = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];

    path = [ pkgs.networkmanager pkgs.gnugrep ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      set -u
      for name in ${builtins.concatStringsSep " " profiles}; do
        ovpn="/run/secrets/$name.ovpn"
        if [ ! -r "$ovpn" ]; then
          echo "skip $name (source missing at $ovpn)"
          continue
        fi
        if nmcli -t -f NAME connection show 2>/dev/null | grep -qx "$name"; then
          echo "$name: already imported"
        else
          echo "$name: importing"
          nmcli connection import type openvpn file "$ovpn" \
            || echo "!! import of $name failed (continuing)"
        fi
      done
    '';
  };
}
