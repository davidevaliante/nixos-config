# STUB. Replace this file on the live ISO during install with the output of:
#
#   sudo nixos-generate-config --no-filesystems --root /mnt
#   sudo cp /mnt/etc/nixos/hardware-configuration.nix \
#           /tmp/nixos-config/hosts/helium/hardware-configuration.nix
#
# The `--no-filesystems` flag skips fileSystems and boot.initrd.luks.devices
# blocks because disko owns those (see ./disko.nix). What this file should
# contain after generation: kernel modules, microcode flag, hostPlatform.
#
# Until replaced, this stub provides the absolute minimum needed for
# `nix flake check` and evaluation to succeed without the real machine.

{ lib, ... }:

{
  imports = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Auto-detected on the target machine; AMD CPU expected:
  # hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  # boot.kernelModules = [ "kvm-amd" ];
}
