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
  compootuersPath = lib.optionalString (config.compootuers.path != null) (
    builtins.toString config.compootuers.path
  );
  computedCompootuers = lib.optionals (compootuersPath != "") (
    builtins.concatLists (
      map (
        system:
        let
          systemPath = "${compootuersPath}/${system}";
          hostNames = builtins.attrNames (builtins.readDir systemPath);
        in
        map (hostname: {
          inherit hostname system;
          src = builtins.toPath "${systemPath}/${hostname}";
        }) hostNames
      ) (builtins.attrNames (builtins.readDir compootuersPath))
    )
  );
  configForSub =
    {
      sub,
      iso ? false,
    }:
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
            { 
              networking.hostName = sub.hostname; 
              nixpkgs.pkgs = withSystem sub.system ({pkgs, ...}: pkgs);
            }
            flake.self.nixosModules.sane
            flake.self.nixosModules.nix-conf
          ]
          ++ lib.optional (sub.src != null && builtins.pathExists "${sub.src}/both.nix") (
            import "${sub.src}/both.nix"
          );
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
                /*
                  For some reason the installation-cd-base.nix sets these two to "", causing a warning
                  and potentially stopping my initialPassword setting from working.
                */
                hashedPasswordFile = null;
                hashedPassword = null;
              };
            }
          ]
          ++ lib.optional (sub.src != null && builtins.pathExists "${sub.src}/iso.nix") (
            import "${sub.src}/iso.nix"
          );
        nonIsoModules =
          [
            flake.self.nixosModules.fakeFileSystems
          ]
          ++ lib.optional (sub.src != null && builtins.pathExists "${sub.src}/default.nix") (
            import "${sub.src}/default.nix"
          );
      in
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit (config) packages;
          inherit
            inputs
            inputs'
            self'
            system
            ;
        };
        modules = baseModules ++ lib.optionals iso isoModules ++ lib.optionals (!iso) nonIsoModules;
      }
    );
in
{
  options.compootuers.path = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
  };
  config = {
    flake.nixosConfigurations = builtins.listToAttrs (
      builtins.concatLists (
        map (
          sub:
          lib.optionals (sub.hostname != null) [
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
        ) computedCompootuers
      )
    );
    systems = lib.unique (builtins.filter (s: s != null) (map (sub: sub.system) computedCompootuers));
  };
}
