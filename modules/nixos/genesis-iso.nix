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
  configForSub =
    {
      sub,
      iso ? false,
    }:
    let
      baseModules = [
        { networking.hostName = sub.hostname; }
        sub.src
        flake.self.nixosModules.default
        flake.nixos-facter-modules.nixosModules.facter
        flake.self.nixosModules.fakeFileSystems
      ];
      modulesPath = "${inputs.nixpkgs.outPath}/nixos";
      isoModules = [
        {
          imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal-new-kernel.nix" ];
          boot.initrd.systemd.enable = lib.mkForce false;
        }
      ];
    in
    withSystem sub.system (
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
        # Append the isoModules only if iso=true, otherwise empty
        modules = baseModules ++ lib.optional iso isoModules;
      }
    );
  config.flake.nixosConfigurations = builtins.listToAttrs (
    lib.concatMap (
      sub:
      if sub.hostname == null then
        [ ]
      else
        [
          {
            name = sub.hostname;
            # normal (non-iso) host
            value = configForSub {
              inherit sub;
              iso = false;
            };
          }
          {
            name = "${sub.hostname}-iso";
            # iso variant
            value = configForSub {
              inherit sub;
              iso = true;
            };
          }
        ]
    ) config.genesis.compootuers
  );
}
