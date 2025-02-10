{ flake, ... }:
{
  config,
  lib,
  inputs,
  withSystem,
  ...
}:
let
  modulesPath = "${inputs.nixpkgs.outPath}/nixos/modules";

  configForSub = { sub, iso ? false, }:
    withSystem sub.system (
      {
        config,
        inputs',
        self',
        system,
        ...
      }:
      let
        baseModules =
          [
            { networking.hostName = sub.hostname; }
            flake.self.nixosModules.sane
            flake.self.nixosModules.nix-conf
          ]
          ++ lib.optional (sub.src != null &&
                          builtins.pathExists (builtins.toString sub.src + "/both.nix"))
               (import (builtins.toString sub.src + "/both.nix"));

        isoModules =
          [
            {
              imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-base.nix" ];
              boot.initrd.systemd.enable = lib.mkForce false;
              isoImage.squashfsCompression = "lz4";
              networking.wireless.enable = lib.mkForce false;
              systemd.targets = {
                sleep.enable = lib.mkForce false;
                suspend.enable = lib.mkForce false;
                hibernate.enable = lib.mkForce false;
                hybrid-sleep.enable = lib.mkForce false;
              };
              users.users.nixos = {
                initialPassword = "iso";
                hashedPasswordFile = null;
                hashedPassword = null;
              };
            }
          ]
          ++ lib.optional (sub.src != null &&
                          builtins.pathExists (builtins.toString sub.src + "/iso.nix"))
               (import (builtins.toString sub.src + "/iso.nix"));

        nonIsoModules =
          [
            flake.self.nixosModules.fakeFileSystems
          ]
          ++ lib.optional (sub.src != null &&
                          builtins.pathExists (builtins.toString sub.src + "/default.nix"))
               (import (builtins.toString sub.src + "/default.nix"));
      in
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit (config) packages;
          inherit inputs inputs' self' system;
          withSystemArch = withSystem system;
        };
        modules = baseModules
          ++ lib.optionals iso isoModules
          ++ lib.optionals (!iso) nonIsoModules;
      }
    );

in
{
  options.compootuers = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        hostname = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        src = lib.mkOption {
          type = lib.types.path;
          default = null;
        };
        system = lib.mkOption {
          type = lib.types.str;
          default = null;
        };
      };
    });
    default = [ ];
  };

  config.flake.nixosConfigurations = builtins.listToAttrs (
    lib.concatMap (sub:
      if sub.hostname == null then [ ]
      else [
        {
          name = sub.hostname;
          value = configForSub { inherit sub; iso = false; };
        }
        {
          name = "${sub.hostname}-iso";
          value = configForSub { inherit sub; iso = true; };
        }
      ]
    ) config.compootuers
  );
}

