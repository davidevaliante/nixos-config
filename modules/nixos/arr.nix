{ lib, username, ... }:

{
  imports = [ ./jellyfin.nix ];

  # Request → acquire → play pipeline around Jellyfin:
  #   Seerr    :5055  request UI ("I want this show"), logs in with Jellyfin accounts
  #   Sonarr   :8989  TV library manager — picks releases, renames, imports
  #   Radarr   :7878  same, for movies
  #   Prowlarr :9696  indexer manager, syncs indexers into Sonarr/Radarr
  #   qBittorrent :8085  download client, saves into /srv/media/downloads
  #   SABnzbd     :8086  Usenet download client, same downloads root
  #   Bazarr      :6767  subtitle manager, fetches subs per language profile
  #   FlareSolverr :8191  Cloudflare-challenge proxy for Prowlarr indexers
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

  # Subtitles are handled separately from the release choice: Bazarr watches
  # the Sonarr/Radarr libraries and downloads subtitle files for the wanted
  # languages next to each video, so they can be switched in the player.
  # In the `media` group so it can write those files into the library.
  services.bazarr = {
    enable = true;
    group = "media";
  };

  # Headless-browser proxy that solves Cloudflare challenges for indexers
  # Prowlarr can't reach directly. Wire it in Prowlarr under Settings →
  # Indexers → Indexer Proxies (http://localhost:8191) with a tag, then put
  # the same tag on the indexers that need it.
  services.flaresolverr.enable = true;

  # Download client for Sonarr/Radarr. `serverConfig` is re-installed over
  # qBittorrent.conf on every service start, so settings changed in the web
  # UI don't survive a restart — change them here instead.
  services.qbittorrent = {
    enable = true;
    group = "media";
    # 8080 (the default) is too likely to clash with dev servers.
    webuiPort = 8085;
    torrentingPort = 51413;
    serverConfig = {
      LegalNotice.Accepted = true;
      BitTorrent.Session.DefaultSavePath = "/srv/media/downloads";
      # The web UI isn't opened on the firewall, so skip the login for
      # localhost; otherwise a random password is printed to the journal on
      # every start. Sonarr/Radarr connect without credentials too.
      Preferences.WebUI.LocalHostAuth = false;
    };
  };
  systemd.services.qbittorrent.serviceConfig.UMask = "0002";

  # Usenet download client for Sonarr/Radarr. `configFile = null` switches
  # the module from its legacy hand-edited ini (the default below
  # stateVersion 26.05) to `settings`; `allowConfigWrite` keeps what's set in
  # the web UI — Usenet provider credentials, API key — in
  # /var/lib/sabnzbd/sabnzbd.ini, out of the store and out of git. The
  # settings below are merged over that file on every start, so they win.
  services.sabnzbd = {
    enable = true;
    group = "media";
    configFile = null;
    allowConfigWrite = true;
    settings.misc = {
      # 8080 (the default) is too likely to clash with dev servers.
      port = 8086;
      download_dir = "/srv/media/downloads/usenet/incomplete";
      complete_dir = "/srv/media/downloads/usenet/complete";
      # Group-writable results so Sonarr/Radarr can move them on import.
      permissions = "775";
    };
  };

    # Incoming peer connections only; the web UI stays localhost-only.
  networking.firewall = {
    allowedTCPPorts = [ 51413 ];
    allowedUDPPorts = [ 51413 ];
  };

  # Group-writable imports, so the desktop user can tidy the library by hand
  # (the modules hardcode 0022).
  systemd.services.sonarr.serviceConfig.UMask = lib.mkForce "0002";
  systemd.services.radarr.serviceConfig.UMask = lib.mkForce "0002";

  # One root with downloads + libraries on the same filesystem, so imports
  # are instant hardlinks/moves instead of copies.
  systemd.tmpfiles.rules = [
    "d /srv/media/downloads 2775 ${username} media -"
    "d /srv/media/downloads/usenet 2775 sabnzbd media -"
    "d /srv/media/downloads/usenet/incomplete 2775 sabnzbd media -"
    "d /srv/media/downloads/usenet/complete 2775 sabnzbd media -"
    "d /srv/media/movies 2775 ${username} media -"
    "d /srv/media/tv 2775 ${username} media -"
  ];
}
