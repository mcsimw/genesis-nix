{ flake, ... }:
{ lib, config, ... }:
{
  imports = [
    (import ./zfsos.nix { inherit config flake lib; })
  ];
  options.fakeFileSystems.nix = {
    enable = lib.mkEnableOption "Enables nix filesystem";
    template = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "zfsos"
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
    ashift = lib.mkOption {
      type = lib.types.nullOr (lib.types.ints.between 9 16);
      description = "Ashift value for ZFS (9-16).";
    };
    swapSize = lib.mkOption {
      type = lib.types.nullOr (lib.types.strMatching "^[0-9]+[MG]$");
      description = "Size of the swap partition (e.g., '8G' or '1024M').";
    };
  };
}
