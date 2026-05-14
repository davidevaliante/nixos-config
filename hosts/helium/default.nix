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

  # The ASUS Aura RGB controller on usb1 port 6 (0b05:1939) wedges on
  # enumeration: descriptor reads fail with `error -110` and the kernel
  # retries for ~85 s, blocking initrd udev ("A stop job is running for
  # Rule-based Manager…"). The kernel reads descriptors in its own hub
  # code path *before* udev sees the device, so a device-level rule
  # (authorized=0 / unbind) fires too late — confirmed by the journal:
  # the rule was installed yet the kernel still looped on error -110.
  # The fix targets the *port* pseudo-device (`usb1-port6`), which the
  # hub driver registers before it starts polling that port for connected
  # devices, giving udev a window to disable the port at the xHCI level:
  #   • disable=1     — takes the port offline, no enumeration attempted
  #   • early_stop=yes — if disable races enumeration, give up after one
  #                      failed try instead of looping ~85 s
  # Applied in both stage-1 initrd and main udev. Side-effect: no Aura
  # RGB control on Linux — acceptable, the controller isn't used.
  services.udev.extraRules = ''
    ACTION=="add", KERNEL=="usb1-port6", ATTR{early_stop}="yes", ATTR{disable}="1"
  '';
  boot.initrd.services.udev.rules = ''
    ACTION=="add", KERNEL=="usb1-port6", ATTR{early_stop}="yes", ATTR{disable}="1"
  '';

  system.stateVersion = "25.11";
}
