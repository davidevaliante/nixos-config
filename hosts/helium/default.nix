{ inputs, ... }:

{
  imports = [
    # disko module + per-host disk layout. Provides fileSystems."/" and
    # "/boot" + boot.initrd.luks.devices.cryptroot from disko.nix, so the
    # generated hardware-configuration.nix is committed with --no-filesystems.
    inputs.disko.nixosModules.disko
    ./disko.nix

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
    ../../modules/nixos/graphics/nvidia.nix
  ];

  # GRUB + os-prober. systemd-boot can't see Windows on a separate disk's
  # ESP, but os-prober scans every mounted filesystem cross-disk and
  # auto-adds a Windows entry — gives a unified boot menu without F11/F12.
  boot.loader = {
    systemd-boot.enable = false;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
      configurationLimit = 10;
    };
  };

  networking.hostName = "helium";

  system.stateVersion = "25.11";
}
