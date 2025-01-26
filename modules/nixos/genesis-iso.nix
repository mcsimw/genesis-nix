{ flake, withSystem, ... }:
{
  config,
  lib,
  inputs,
  ...
}:
let
  configForSub =
    {
      sub,
      iso ? false,
    }:
    let
      modulesPath = "${inputs.nixpkgs.outPath}/nixos";

      baseModules = [
        { networking.hostName = sub.hostname; }
        sub.src
        # Your modules here:
        flake.self.nixosModules.default
        flake.nixos-facter-modules.nixosModules.facter
        flake.self.nixosModules.fakeFileSystems
      ];

      # Extra modules for the ISO variant
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

        # Pass any special arguments down if needed:
        specialArgs = withSystem sub.system (
          { inputs', self', ... }:
          {
            inherit (config) packages;
            inherit self' inputs' inputs;
          }
        );

        # If iso=true, we append isoModules.  Otherwise, we append [].
        modules = baseModules ++ lib.optional iso isoModules;
      }
    );
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
      description = "List of host definitions (compootuers).";
      default = [ ];
    };
  };
  config.flake.nixosConfigurations = builtins.listToAttrs (
    lib.concatMap (
      sub:
      if sub.hostname == null then
        # Skip if no hostname
        [ ]
      else
        [
          {
            name = sub.hostname;
            value = configForSub {
              inherit sub;
              iso = false;
            };
          }
          {
            name = "${sub.hostname}-iso";
            value = configForSub {
              inherit sub;
              iso = true;
            };
          }
        ]
    ) config.genesis.compootuers
  );
}
