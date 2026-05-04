{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/desktops/gnome.nix
    ../../modules/nixos/desktops/hyprland.nix
    ../../modules/nixos/desktops/niri.nix
    ../../modules/nixos/stylix.nix
    ../../modules/nixos/sops.nix
    ../../modules/nixos/aws.nix
    ../../modules/nixos/openvpn.nix
    ../../modules/nixos/rquickshare.nix
    ../../modules/nixos/thunar.nix
    ../../modules/nixos/portal.nix
  ];

  boot.loader.systemd-boot = {
    enable = true;
    # /boot is only 96MB on this host and each generation's initrd is ~50MB.
    # Keeping more than 2 generations fills the partition.
    # Long-term fix: repartition /boot to 512MB+. Until then, keep it tight.
    configurationLimit = 2;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "hydrogen";

  system.stateVersion = "25.11";
}
