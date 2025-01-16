{
  config,
  lib,
  inputs,
  ...
}:
{
  options.genesis = {
    compootuers = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            hostname = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                Optional hostname. If null or not set, this submodule is ignored.
              '';
            };
            src = lib.mkOption {
              type = lib.types.path;
              description = ''
                The path to the configuration file or directory for this host.
              '';
            };
          };
        }
      );
    };
  };
  config.flake.nixosConfigurations = builtins.listToAttrs (
    map (sub: {
      name = sub.hostname;
      value = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          sub.src
          inputs.nixos-facter-modules.nixosModules.facter
          inputs.nixembryo.nixosModules.default
          inputs.chaotic.nixosModules.default

          {
            nixpkgs.config.allowUnfree = true;
          }
        ];
      };
    }) (lib.filter (sub: sub.hostname != null) config.genesis.compootuers)
  );
}
