{ inputs, pkgs, ... }:

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
    ../../modules/nixos/localsend.nix
    ../../modules/nixos/thunar.nix
    ../../modules/nixos/portal.nix
    ../../modules/nixos/graphics/nvidia.nix
    ../../modules/nixos/cosmo.nix
  ];

  # os-prober mounts NTFS to confirm a partition is Windows; without
  # ntfs support it silently skips the Windows disk.
  boot.supportedFilesystems = [ "ntfs" ];

  # AM4 / Ryzen 5000 desktops frequently hang on S3 deep-sleep resume
  # (kernel logs "suspend entry (deep)" with no matching resume). Force
  # s2idle so /sys/power/mem_sleep defaults to the working mode; tradeoff
  # is slightly higher idle power than S3.
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];

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

  # The desk mouse on helium reports very high counts-per-inch; slow it
  # down at the libinput layer so X11/Xwayland clients match the Wayland
  # compositor settings (Hyprland/Niri set their own accel-speed too).
  services.libinput.mouse.accelSpeed = "-0.1";

  # The ASUS Aura onboard RGB controller (0b05:1939, sits on usb1 port 6)
  # gets wedged by power transitions: descriptor reads fail with
  # `error -110` and the kernel retries for ~65 s, blocking initrd udev
  # ("A stop job is running for Rule-based Manager…"). The previous
  # unbind-on-shutdown service ran fine but the device kept re-enumerating
  # on the next boot — and the shutdown-initrd phase still hit the wedge.
  # Instead, de-authorize the device at first sight: with authorized=0
  # the USB core never issues descriptor reads, so the wedge is invisible.
  # Applied in both stage-1 initrd and the main system so the rule fires
  # everywhere udev runs. Side-effect: no Aura RGB control on Linux —
  # acceptable here, the controller isn't used.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0b05", ATTR{idProduct}=="1939", ATTR{authorized}="0"
  '';
  boot.initrd.services.udev.rules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0b05", ATTR{idProduct}=="1939", ATTR{authorized}="0"
  '';

  system.stateVersion = "25.11";
}
