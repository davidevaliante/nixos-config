{ username, ... }:

{
  # Trial run on a daily driver before moving to the homelab. State lives in
  # /var/lib/jellyfin (config, metadata, users) and /var/cache/jellyfin
  # (transcodes) — copy /var/lib/jellyfin over to migrate the library as-is.
  # Web UI: http://localhost:8096
  services.jellyfin = {
    enable = true;
    # 8096/8920 TCP (HTTP/HTTPS) + 1900/7359 UDP (DLNA / client auto-discovery)
    # so TVs and phones on the LAN can reach it.
    openFirewall = true;
  };

  # The service runs as the `jellyfin` user, which can't traverse the 0700
  # home directory. Give it a shared library root instead: setgid + group
  # `media` so files dropped in by the desktop user (or by Sonarr/Radarr,
  # see arr.nix) stay readable by everything in the stack.
  users.groups.media = { };
  users.users.${username}.extraGroups = [ "media" ];
  systemd.tmpfiles.rules = [
    "d /srv/media 2775 ${username} media -"
  ];

  # render/video grant access to /dev/dri for hardware transcoding
  # (NVENC on helium, QSV/VA-API on Intel hosts).
  users.users.jellyfin.extraGroups = [ "media" "render" "video" ];
}
