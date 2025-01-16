{ flake, ... }:
{ lib, ... }:
{
  imports = [
    flake.disko.nixosModules.disko
    ./zfsos.nix
    ./bcachefsos.nix
  ];
  options.fakeFileSystems.nix = {
    enable = lib.mkEnableOption "Enables nix filesystem";
    template = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "zfsos"
          "bcachefsos"
        ]
      );
      default = null;
    };
    device = lib.mkOption {
      type = lib.types.str;
      description = "The device to use for the disk";
    };
    diskName = lib.mkOption {
      type = lib.types.str;
      description = "name of disk";
    };
    ashift = lib.mkOption {
      type = lib.types.str;
      description = "ashift of disk";
    };
    swapSize = lib.mkOption {
      type = lib.types.str;
      description = "size of swap partition";
    };
  };
}
