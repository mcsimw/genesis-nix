{ localFlake, ... }:
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
        map (hostName: {
          inherit hostName system;
          src = builtins.toPath "${systemPath}/${hostName}";
        }) hostNames
      ) (builtins.attrNames (builtins.readDir compootuersPath))
    )
  );
  configForSub =
    {
      sub,
      iso ? false,
    }:
    let
      inherit (sub) system src;
    in
    withSystem system (
      {
        config,
        inputs',
        self',
        system,
        ...
      }:
      let
        baseModules = [
          {
            networking.hostName = hostName;
            nixpkgs.pkgs = withSystem system ({ pkgs, ... }: pkgs);
          }
          localFlake.nixosModules.sane
          localFlake.nixosModules.nix-conf
        ] ++ lib.optional (src != null && builtins.pathExists "${src}/both.nix") (import "${src}/both.nix");
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
        ] ++ lib.optional (src != null && builtins.pathExists "${src}/iso.nix") (import "${src}/iso.nix");
        nonIsoModules = lib.optional (src != null && builtins.pathExists "${src}/default.nix") (
          import "${src}/default.nix"
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
          lib.optionals (hostName != null) [
            {
              name = hostName;
              value = configForSub {
                inherit sub;
                iso = false;
              };
            }
            {
              name = "${hostName}-iso";
              value = configForSub {
                inherit sub;
                iso = true;
              };
            }
          ]
        ) computedCompootuers
      )
    );
    systems = lib.unique (
      builtins.filter (s: s != null) (map ({ system, ... }: system) computedCompootuers)
    );
  };
}
