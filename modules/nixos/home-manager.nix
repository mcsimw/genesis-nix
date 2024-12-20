{
  lib,
  config,
  options,
  ...
}:

{
  config = lib.optionalAttrs (options ? home-manager) {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "old";
      verbose = true;
      sharedModules = [
        {
          home.stateVersion = lib.mkForce config.system.stateVersion;
          nix.package = lib.mkForce config.nix.package;
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };
  };
}
