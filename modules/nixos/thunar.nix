{ pkgs, ... }:

{
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin   # right-click → Extract / Create archive
      thunar-volman           # auto-mount removable media
    ];
  };

  # thunar-archive-plugin only ships .tap descriptors for file-roller/engrampa/ark
  # (xarchiver.tap lives in xarchiver's own derivation and isn't picked up by
  # nixpkgs' thunar-with-plugins symlinkJoin), so the frontend has to be one of
  # those. CLI tools (unzip in common.nix, zip/p7zip here) do the actual work.
  environment.systemPackages = with pkgs; [
    file-roller
    zip
    p7zip
  ];

  # Trash, network shares (smb://, sftp://), and similar live in gvfs daemons —
  # without them Thunar silently loses those features.
  services.gvfs.enable = true;
  services.tumbler.enable = true;   # thumbnails for image/video previews

  # Thunar persists prefs via xfconf; required even outside a full XFCE session.
  programs.xfconf.enable = true;
}
