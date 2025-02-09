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
    {
      sub,
      iso ? false,
    }:
    let
      baseModules = [
        {
          networking.hostName = sub.hostname;
          nix.settings = {
            substituters = [
              "https://nix-community.cachix.org"
            ];
            trusted-public-keys = [
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            ];
          };
        }
        flake.self.nixosModules.sane
        flake.self.nixosModules.nix-conf
      ] ++ lib.optionals (sub.both != null) [ sub.both ];
      isoModules = [
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
            /*
               For some reason the installation-cd-base.nix sets these two to "", causing a warning
               and potentially stopping my initialPassword setting from working.
            */
            hashedPasswordFile = null;
            hashedPassword = null;
          };
        }
      ] ++ lib.optionals (sub.iso != null) [ sub.iso ];
      nonIsoModules = [
        flake.self.nixosModules.fakeFileSystems
      ] ++ lib.optionals (sub.src != null) [ sub.src ];
    in
    withSystem sub.system (
      _:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = withSystem sub.system (
          {
            inputs',
            self',
            system,
            packages,
            ...
          }:
          {
            inherit
              self'
              inputs'
              inputs
              system
              ;
            withSystemArch = withSystem system;
            inherit (config) packages;
          }
        );
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
          both = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
          };
          iso = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
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
