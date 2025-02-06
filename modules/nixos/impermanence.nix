{ flake, ... }:
{
  config,
  ...
}:
{
  imports = [
    flake.impermanence.nixosModules.impermanence
  ];
  config = {
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
