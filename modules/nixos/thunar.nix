{ pkgs, ... }:

{
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin   # right-click → Extract / Create archive
      thunar-volman           # auto-mount removable media
    ];
  };

  # Trash, network shares (smb://, sftp://), and similar live in gvfs daemons —
  # without them Thunar silently loses those features.
  services.gvfs.enable = true;
  services.tumbler.enable = true;   # thumbnails for image/video previews

  # Thunar persists prefs via xfconf; required even outside a full XFCE session.
  programs.xfconf.enable = true;
}
