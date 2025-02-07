{ flake, ... }:
{ lib, config, ... }:
{
  imports = [
    flake.disko.nixosModules.disko
    (import ./bcachefsos.nix { inherit config flake lib; })
  ];
  options.fakeFileSystems.nix = {
    enable = lib.mkEnableOption "Enables nix filesystem";
    template = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "bcachefsos"
        ]
      );
      default = null;
    };
    device = lib.mkOption {
      type = lib.types.path;
      description = "The block device to use for the filesystem.";
    };
    diskName = lib.mkOption {
      type = lib.types.strMatching "^[a-zA-Z0-9_-]+$";
      description = "The name of the disk.";
    };
    swapSize = lib.mkOption {
      type = lib.types.strMatching "^[0-9]+[MG]$";
      description = "Size of the swap partition (e.g., '8G' or '1024M').";
    };
    nixSize = lib.mkOption {
      type = lib.types.strMatching "^[0-9]+[MG]$";
      description = "Size of the nix partition (e.g., '8G' or '1024M').";
    };
  };
}
