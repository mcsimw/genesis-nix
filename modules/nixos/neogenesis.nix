{ flake, withSystem, ... }:
let
  computeSystems =
    compootuers:
    builtins.unique (map (h: h.system) (builtins.filter (h: h.hostname != null) compootuers));
in
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
              description = "Optional hostname. If null or not set, this submodule is ignored.";
            };
            src = lib.mkOption {
              type = lib.types.path;
              description = "The path to the configuration file or directory for this host.";
            };
            system = lib.mkOption {
              type = lib.types.str;
              default = "x86_64-linux";
              description = "The Nix system architecture (e.g., \"x86_64-linux\", \"aarch64-linux\").";
            };
          };
        }
      );
    };
  };
  configForMap = config;
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
              inherit (configForMap) packages;
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
    }) (lib.filter (sub: sub.hostname != null) configForMap.genesis.compootuers)
  );
  inherit computeSystems;
}
