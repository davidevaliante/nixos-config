# Declarative disk layout for helium. Applied via:
#
#   sudo nix --experimental-features 'nix-command flakes' run \
#     github:nix-community/disko -- --mode destroy,format,mount \
#     ./hosts/helium/disko.nix
#
# Layout:
#   • SSD #2 (the empty drive — Windows lives untouched on SSD #1):
#       p1: 1 GiB ESP, vfat, mounted at /boot
#       p2: rest of disk, LUKS2 → ext4, mounted at /
#
# The ESP is sized at 1 GiB so 10+ generations of stylix-themed initrds
# (~60-80 MB each) fit comfortably without pruning.
#
# IMPORTANT: replace REPLACE_ME below with the by-id path of the second SSD,
# captured on the live ISO via `ls -l /dev/disk/by-id/`. Do this before
# running disko — picking the wrong device destroys data.

{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/REPLACE_ME";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              # discards: needed for SSD TRIM through LUKS. Tiny security
              # tradeoff (leaks block usage patterns) — acceptable for a
              # daily driver, not for a covert-channel-sensitive deployment.
              settings.allowDiscards = true;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
