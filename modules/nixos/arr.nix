{ lib, username, ... }:

{
  imports = [ ./jellyfin.nix ];

  # Request → acquire → play pipeline around Jellyfin:
  #   Seerr    :5055  request UI ("I want this show"), logs in with Jellyfin accounts
  #   Sonarr   :8989  TV library manager — picks releases, renames, imports
  #   Radarr   :7878  same, for movies
  #   Prowlarr :9696  indexer manager, syncs indexers into Sonarr/Radarr
  # A download client (qBittorrent/SABnzbd) is the remaining piece; point it
  # at /srv/media/downloads.
  #
  # Seerr is the merged successor of Overseerr (Plex-only, archived) and
  # Jellyseerr; it talks to Jellyfin directly, so Plex isn't needed.
  services.seerr = {
    enable = true;
    stateRevision = 1;
    # The only UI meant for non-admin users, so it's the only one on the LAN.
    openFirewall = true;
  };

  # Sonarr/Radarr run in the shared `media` group so their imports land
  # group-owned next to Jellyfin's library. Admin UIs stay localhost-only.
  services.sonarr = {
    enable = true;
    group = "media";
  };
  services.radarr = {
    enable = true;
    group = "media";
  };
  services.prowlarr.enable = true;

  # Group-writable imports, so the desktop user can tidy the library by hand
  # (the modules hardcode 0022).
  systemd.services.sonarr.serviceConfig.UMask = lib.mkForce "0002";
  systemd.services.radarr.serviceConfig.UMask = lib.mkForce "0002";

  # One root with downloads + libraries on the same filesystem, so imports
  # are instant hardlinks/moves instead of copies.
  systemd.tmpfiles.rules = [
    "d /srv/media/downloads 2775 ${username} media -"
    "d /srv/media/movies 2775 ${username} media -"
    "d /srv/media/tv 2775 ${username} media -"
  ];
}
