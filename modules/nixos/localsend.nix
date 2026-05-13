{ ... }:

{
  # LocalSend uses fixed port 53317 for both peer discovery (UDP multicast on
  # 224.0.0.167) and file transfer (TCP/HTTPS). Opening the single port on the
  # firewall is enough — no need to trust whole interfaces.
  networking.firewall = {
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

  # Not strictly required by LocalSend (it has its own UDP multicast discovery
  # protocol on 224.0.0.167), but useful for general .local hostname resolution
  # and printer/scanner discovery on the LAN.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
