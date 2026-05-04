{ ... }:

{
  # Quick Share discovers peers over mDNS-SD, so avahi must be running and
  # UDP 5353 must be reachable. `openFirewall = true` handles the latter.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # The actual file transfer uses an ephemeral TCP port chosen at runtime, so
  # there's no single port to whitelist. Trusting the LAN interfaces is the
  # least-bad option: pairing only happens on the LAN, and the firewall still
  # blocks everything from the internet side. If you regularly join networks
  # you don't trust, drop these and selectively open ports on the day instead.
  networking.firewall.trustedInterfaces = [ "wlo1" "enp3s0" ];
}
