{ username, ... }:

{
  # Authenticator (GNOME TOTP app) stores codes locally in
  # ~/.local/share/authenticator/authenticator.db. We snapshot it into sops
  # so every host boots with a baseline set of TOTP entries.
  #
  # Sync workflow: pick one host as "primary" (the one where you add new
  # codes). After adding a code there, re-encrypt the DB and push:
  #
  #   nix-shell -p sops --run \
  #     'sops -e --input-type binary --output-type json \
  #       --filename-override secrets/common/authenticator-db.yaml \
  #       ~/.local/share/authenticator/authenticator.db \
  #       > secrets/common/authenticator-db.yaml'
  #
  # Other hosts pick it up on the next `git pull && nixos-rebuild switch`
  # because the activation script below always overwrites the local DB
  # from sops. Adding a code on a non-primary host without pushing first
  # is the way to lose data — pick one primary and stick to it.

  sops.secrets."authenticator-db" = {
    sopsFile = ../../secrets/common/authenticator-db.yaml;
    format = "binary";
  };

  system.activationScripts.authenticatorDb = {
    text = ''
      if [ -e /run/secrets/authenticator-db ]; then
        install -D -m 0644 -o ${username} -g users \
          /run/secrets/authenticator-db \
          /home/${username}/.local/share/authenticator/authenticator.db
      fi
    '';
    deps = [ "setupSecrets" ];
  };
}
