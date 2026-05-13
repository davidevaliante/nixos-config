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
  # gets wedged by suspend AND shutdown/reboot: on the next boot it stops
  # answering descriptor reads and the kernel retries for ~65 s, blocking
  # the initrd→sysroot udev handoff (visible as a "Stop Job is running for
  # Rule-based Manager…" message, with `usb 1-6: device descriptor
  # read/64, error -110` in dmesg). Unbind it before both sleep and
  # shutdown so the device is detached cleanly and isn't dragged through
  # the power transition.
  systemd.services.unbind-asus-aura = {
    description = "Unbind ASUS Aura USB controller before suspend/shutdown";
    before = [ "sleep.target" "shutdown.target" ];
    wantedBy = [ "sleep.target" "shutdown.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "unbind-asus-aura" ''
        set -eu
        for d in /sys/bus/usb/devices/*; do
          [ -e "$d/idVendor" ] || continue
          if [ "$(cat "$d/idVendor")" = "0b05" ] \
             && [ "$(cat "$d/idProduct")" = "1939" ]; then
            echo "$(basename "$d")" > /sys/bus/usb/drivers/usb/unbind || true
          fi
        done
      '';
    };
  };

  system.stateVersion = "25.11";
}
