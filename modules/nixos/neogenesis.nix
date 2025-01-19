{ flake, withSystem, ... }:
{
  config,
  lib,
  inputs,
  ...
}:
{
  _type = "merge";
  systems = {
    _type = "merge";
    merges = [
      {
        _type = "inherit";
        path = "systems";
      }
      {
        _type = "literalExample";
        value = builtins.unique (
          map (sub: sub.system) (lib.filter (sub: sub.hostname != null) config.genesis.compootuers)
        );
      }
    ];
  };
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
        _:
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
            { networking.hostName = sub.hostname; }
            sub.src
            flake.self.nixosModules.default
            flake.nixos-facter-modules.nixosModules.facter
            flake.self.nixosModules.fakeFileSystems
          ];
        }
      );
    }) (lib.filter (sub: sub.hostname != null) config.genesis.compootuers)
  );
}
