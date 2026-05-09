{ config, pkgs, username, ... }:

{
  # Cosmo dev host: lets the user run cosmo-agent + Firecracker microVMs
  # locally. Companion to ~/personal/cosmo (DEV_LOOP_PLAN.md, Phase 3).

  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];

  # The agent enforces ip_forward=1 at runtime via sysctl -w; declaring it
  # here makes it survive reboots without requiring the agent to be running.
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # Docker daemon for the cosmo-compose stack (postgres, NATS, ClickHouse,
  # api, sshproxy, prometheus, grafana). cosmo-agent itself runs as a host
  # process — needs /dev/kvm + raw networking.
  virtualisation.docker.enable = true;

  # kvm: so /dev/kvm is openable. docker: so `docker compose` doesn't need
  # sudo. Re-login required to pick these up.
  users.users.${username}.extraGroups = [ "kvm" "docker" ];

  # NOPASSWD for the three commands cosmo-agent shells out to via its
  # COSMO_PRIVILEGE_HELPER="sudo -n" hook (internal/firecracker/network.go).
  # Scoped to the dev user and to specific binaries — no shell escape.
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        { command = "/run/current-system/sw/bin/ip";       options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/iptables"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/sysctl";   options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  # Open the dev stack's host-mapped ports.
  networking.firewall.allowedTCPPorts = [
    8080  # cosmo-api
    2222  # sshproxy user SSH
    2200  # sshproxy agent tunnels
    4222  # NATS client
    8222  # NATS monitoring
    9090  # prometheus
    3001  # grafana
    25432 # postgres (host-mapped from 5432)
    8123  # clickhouse http
  ];
}
