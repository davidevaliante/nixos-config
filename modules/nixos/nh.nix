{ ... }:

{
  # nh wraps nixos-rebuild and runs `nvd diff` automatically between the
  # current system and the freshly built one, so package-level changes are
  # visible before activation. `clean` is a systemd timer that prunes old
  # generations across every nix profile (system + user + home-manager) on
  # the chosen schedule — pairs with `boot.loader.*.configurationLimit`,
  # which only governs bootloader entries, not store roots.
  programs.nh = {
    enable = true;
    flake = "/home/davide/nixos-config";
    clean = {
      enable = true;
      dates = "weekly";
      # Keep at least 5 most-recent generations and anything younger than 7
      # days, even if older than the 5th. Tight enough to actually free
      # space, loose enough to roll back a bad rebuild from a week ago.
      extraArgs = "--keep 5 --keep-since 7d";
    };
  };
}
