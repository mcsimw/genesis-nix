{
  lib,
  config,
  flake,
  ...
}:
let
  cfg = config.fakeFileSystems.nix;
in
{
  imports = [
    ./zfs-rollback.nix
    flake.self.nixosModules.impermanence
  ];
  config = lib.mkIf (cfg.enable && cfg.template == "zfsos") (
    {
      boot.kernelParams = [ "nohibernate" ];
      fileSystems = {
        "/".neededForBoot = true;
        "/persist".neededForBoot = true;
        "/mnt/${cfg.diskName}".neededForBoot = true;
      };
      zfs-rollback = {
        enable = true;
        snapshot = "blank";
        volume = "${cfg.diskName}-zfsos/faketmpfs";
      };
    }
    // (import ../disko-templates/zfsos.nix {
      inherit (cfg)
        diskName
        device
        ashift
        swapSize
        ;
    })
  );
}
