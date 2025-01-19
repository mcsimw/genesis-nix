{
  config,
  lib,
  pkgs,
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
          map (host: host.system) (lib.filter (host: host.hostname != null) config.genesis.compootuers)
        );
      }
    ];
  };
  nixosModule = {
    options.genesis.compootuers = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            hostname = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Hostname, or null if unused.";
            };
            src = lib.mkOption {
              type = lib.types.path;
              description = "NixOS config file/directory for this host.";
            };
            system = lib.mkOption {
              type = lib.types.str;
              default = "x86_64-linux";
              description = "Architecture, e.g. 'x86_64-linux' or 'aarch64-linux'.";
            };
          };
        }
      );
      default = [ ];
      description = "List of computers built by neogenesis.";
    };
    config.flake.nixosConfigurations = builtins.listToAttrs (
      map (sub: {
        name = sub.hostname;
        value = pkgs.nixosSystem {
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
            inputs.nixembryo.nixosModules.default
            inputs.nixembryo.nixos-facter-modules.nixosModules.facter
            inputs.nixembryo.nixosModules.fakeFileSystems
          ];
        };
      }) (lib.filter (sub: sub.hostname != null) config.genesis.compootuers)
    );
  };
}
