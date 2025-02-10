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

  configForSub =
    { sub, iso ? false, }:
    let
      baseModules =
        if sub.src != null then
          [
            {
              networking.hostName = sub.hostname;
            }
            flake.self.nixosModules.sane
            flake.self.nixosModules.nix-conf
          ]
          ++ (if builtins.pathExists (builtins.toString sub.src + "/both.nix")
              then [ (import (builtins.toString sub.src + "/both.nix")) ]
              else [])
        else
          [
            {
              networking.hostName = sub.hostname;
            }
            flake.self.nixosModules.sane
            flake.self.nixosModules.nix-conf
          ];

      isoModules =
        if sub.src != null then
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
          ++ (if builtins.pathExists (builtins.toString sub.src + "/iso.nix")
              then [ (import (builtins.toString sub.src + "/iso.nix")) ]
              else [])
        else
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
          ];

      nonIsoModules =
        if sub.src != null then
          [
            flake.self.nixosModules.fakeFileSystems
          ]
          ++ (if builtins.pathExists (builtins.toString sub.src + "/default.nix")
              then [ (import (builtins.toString sub.src + "/default.nix")) ]
              else [])
        else
          [
            flake.self.nixosModules.fakeFileSystems
          ];
    in
    withSystem sub.system (
      {
        config,
        inputs',
        self',
        system,
        ...
      }:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit (config) packages;
          inherit
            inputs
            inputs'
            self'
            system;
          withSystemArch = withSystem system;
        };
        modules = baseModules ++ lib.optionals iso isoModules ++ lib.optionals (!iso) nonIsoModules;
      }
    );
in
{
  options.compootuers = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
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
      }
    );
    default = [ ];
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
    ) config.compootuers
  );
}

