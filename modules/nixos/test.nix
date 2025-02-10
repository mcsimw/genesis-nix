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

  # Given a base path, return a set with our standardized module paths.
  completeSrc = base: {
    iso    = builtins.toPath "${builtins.toString base}/iso.nix";
    nonIso = builtins.toPath "${builtins.toString base}/non-iso.nix";
    both   = builtins.toPath "${builtins.toString base}/both.nix";
  };

  configForSub =
    { sub, iso ? false }:
    let
      # Base modules are common to both ISO and non‑ISO configurations.
      # They include the hostname, some shared modules, and then the “both”
      # module. If the user provided an explicit “both” module, use it;
      # otherwise, if they provided a base directory in `src`, use the file at <src>/both.nix.
      baseModules =
        [ {
            networking.hostName = sub.hostname;
          }
        , flake.self.nixosModules.sane
        , flake.self.nixosModules.nix-conf
        ]
        ++ (if sub.both != null then [ sub.both ]
            else if sub.src != null then [ (completeSrc sub.src).both ]
            else []);

      # ISO‐specific modules: these include the standard installer modules and
      # disable certain features. Again, if the user provided an explicit iso module,
      # that takes precedence; otherwise, if a base directory was given, use <src>/iso.nix.
      isoModules =
        [ {
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
              # The installer module sometimes overrides these values.
              hashedPasswordFile = null;
              hashedPassword = null;
            };
          }
        ]
        ++ (if sub.iso != null then [ sub.iso ]
            else if sub.src != null then [ (completeSrc sub.src).iso ]
            else []);

      # Non‑ISO modules: for example, here we add a fake file systems module.
      # If a base directory is provided, we also include the file <src>/non-iso.nix.
      nonIsoModules =
        [ flake.self.nixosModules.fakeFileSystems ]
        ++ (if sub.src != null then [ (completeSrc sub.src).nonIso ] else []);

    in
    withSystem sub.system { config, inputs', self', system, ... }:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit (config) packages;
          inherit inputs inputs' self' system;
          withSystemArch = withSystem system;
        };
        modules =
          baseModules
          ++ (if iso then isoModules else nonIsoModules);
      };

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
            # The user can provide a base directory (e.g. ./eldritch)
            # that is automatically completed to iso.nix, non-iso.nix and both.nix.
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
    lib.concatMap (sub:
      if sub.hostname == null then [] else [
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

