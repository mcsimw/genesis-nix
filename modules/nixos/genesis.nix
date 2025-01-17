{ flake, withSystem, ... }:
{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [
    flake.treefmt-nix.flakeModule
  ];
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

            system = lib.mkOption {
              type = lib.types.str;
              default = "x86_64-linux";
              description = ''
                The Nix system architecture (e.g., "x86_64-linux", "aarch64-linux").
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
      value = withSystem sub.system (
        flake.nixpkgs.lib.nixosSystem {
          inherit (sub) system;
          specialArgs = withSystem sub.system (
            { inputs', self', ... }:
            {
              inherit (config) packages;
              inherit self' inputs' inputs;
            }
          );
          modules = [
            sub.src
            flake.nixos-facter-modules.nixosModules.facter
            flake.self.nixosModules.default
            flake.self.nixosModules.fakeFileSystems
            inputs.chaotic.nixosModules.default
            {
              nixpkgs.config.allowUnfree = true;
              networking.hostName = sub.hostname;
            }
          ];
        }
      );
    }) (lib.filter (sub: sub.hostname != null) config.genesis.compootuers)
  );
}
