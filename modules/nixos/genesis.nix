{ localFlake, withSystem, ... }:
{
  config,
  lib,
  inputs,
  ...
}:
let

  modulesPath = "${localFlake.nixpkgs.outPath}/nixos/modules";
  configForSub =
    {
      sub,
      iso ? false,
    }:
    let
      baseModules = [
        { networking.hostName = sub.hostname; }
        sub.src
        localFlake.self.nixosModules.default
        localFlake.self.nixosModules.fakeFileSystems
      ];
      isoModules = [
        {
          imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-base.nix" ];
          boot.initrd.systemd.enable = lib.mkForce false;
          isoImage.squashfsCompression = "lz4";
          networking.wireless.enable = lib.mkForce false;
          nixpkgs = {
            hostPlatform = { inherit (sub) system; };
            config.allowUnfree = true;
          };
        }
      ];
      nonIsoModules = [
        inputs.nixpkgs.nixosModules.readOnlyPkgs
      ];
    in
    withSystem sub.system (
      _:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = withSystem sub.system (
          {
            inputs',
            self',
            ...
          }:
          {
            inherit
              self'
              inputs'
              inputs
              ;
          }
        );
        modules = baseModules ++ lib.optionals iso isoModules ++ lib.optionals (!iso) nonIsoModules;
      }
    );
in
{
  imports = [
    localFlake.treefmt-nix.flakeModule
  ];
  options.genesis = {
    compootuers = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            hostname = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            src = lib.mkOption {
              type = lib.types.path;
            };
            system = lib.mkOption {
              type = lib.types.str;
              default = "x86_64-linux";
            };
          };
        }
      );
    };
  };
  config.flake.nixosConfigurations = builtins.listToAttrs (
    lib.concatMap (
      sub:
      if sub.hostname == null then
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
