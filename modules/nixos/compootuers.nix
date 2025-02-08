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
          nixpkgs.pkgs = withSystem sub.system ({ pkgs, ... }: pkgs);
        }
        flake.self.nixosModules.sane
        flake.self.nixosModules.nix-conf
        flake.chaotic.nixosModules.mesa-git
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
        inputs.nixpkgs.nixosModules.readOnlyPkgs
      ] ++ lib.optionals (sub.src != null) [ sub.src ];
    in
    withSystem sub.system (
      _:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = withSystem sub.system (
          { inputs', self', ... }:
          {
            inherit self' inputs' inputs;
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
  config = {
    perSystem =
      {
        pkgs,
        system,
        ...
      }:
      {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = with flake; [
            nix.overlays.default
            emacs-overlay.overlays.default
            chaotic.overlays.default
          ];
        };
      };
    flake.nixosConfigurations = builtins.listToAttrs (
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
  };
  imports = [
    flake.treefmt-nix.flakeModule
  ];
}
