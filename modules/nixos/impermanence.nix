{
  lib,
  config,
  options,
  ...
}:
{
  config = lib.optionalAttrs (options.environment ? persistence) {
    environment.persistence."/persist" = {
      enable = true;
      hideMounts = true;
      directories = [
        "/var/lib/nixos"
        "/var/log"
        "/var/lib/systemd/coredump"
      ];
    };
  };
}
