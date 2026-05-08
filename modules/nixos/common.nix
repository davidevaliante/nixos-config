{ pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://niri.cachix.org"
      "https://noctalia.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # Wipe /tmp at boot. Default is `false` (preserves /tmp across reboots),
  # which lets orphaned files accumulate — notably NVIDIA's VRAM snapshot
  # written by nvidia-suspend.service when resume fails before the driver
  # can delete it (multi-GB on a 3060 Ti). Cheap insurance against any
  # crashed-process leftover, not just NVIDIA.
  boot.tmp.cleanOnBoot = true;

  time.timeZone = "Europe/Rome";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  networking.networkmanager.enable = true;

  # dbus-broker is a drop-in replacement for the reference dbus daemon written
  # in C with a single-process model. ~3-5x lower IPC latency in practice, which
  # GTK/Qt apps notice on cold launch (they make many dbus calls during init).
  services.dbus.implementation = "broker";

  # NixOS-specific hint that the Electron/Chromium wrappers in nixpkgs check.
  # When set, they pass `--ozone-platform-hint=auto` so the app runs natively on
  # Wayland instead of falling back to XWayland. Affects Slack, Chrome, VS Code,
  # Discord, and other Electron apps — measurably faster cold starts plus proper
  # GPU acceleration.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Pull in `linux-firmware`, which carries the closed-source-but-redistributable
  # blobs required by USB BT dongles (e.g. TP-Link UB500 → rtl_bt/rtl8761bu_fw.bin),
  # most Wi-Fi cards, and AMD/Intel GPU microcode. Without this, `btusb` brings
  # the device up but firmware load fails with -ENOENT and hci0 never works.
  hardware.enableRedistributableFirmware = true;

  # Bluetooth — pipewire handles audio routing for BT headphones automatically
  # (LDAC/AAC/aptX work on modern wireplumber). Pairing happens via noctalia's
  # bluetooth panel; no `blueman` GUI needed.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    # Modern headphones advertise mostly over BLE; the friendly name lives
    # in the *scan-response* packet, not the initial advertisement, so it
    # only resolves with a long-enough LE scan window. Combined with bluez's
    # default `[GATT] Cache = always` (which caches the empty-name first
    # response), devices can stick at "MAC only" forever. The settings
    # below open scan params, switch the cache to "yes" (only stores
    # confirmed entries), and enable the LE-friendly flags.
    settings = {
      General = {
        Experimental = true;
        JustWorksRepairing = "always";
        FastConnectable = true;
        Privacy = "device";
        ControllerMode = "dual";
      };
      Policy.AutoEnable = true;
      GATT.Cache = "yes";
    };
  };

  # OpenSSH server is enabled so the host has a stable ed25519 host key —
  # sops-nix derives the host's age decryption identity from it via ssh-to-age.
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      # Flip to `true` temporarily to seed a new client's pubkey via ssh-copy-id, then revert.
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.printing.enable = true;

  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    neovim
    git
    wget
    libnotify
    unzip
  ];
}
