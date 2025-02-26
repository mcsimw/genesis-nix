{ localFlake, ... }:
{
  config,
  lib,
  inputs,
  withSystem,
  self,
  ...
}:
let
  modulesPath = "${inputs.nixpkgs.outPath}/nixos/modules";
  allCompootuersPath =
    if config.allCompootuers.path == null then null else builtins.toPath config.allCompootuers.path;

  hasAllCompootuers = allCompootuersPath != null && builtins.pathExists allCompootuersPath;

  globalBoth = lib.optional (
    hasAllCompootuers && builtins.pathExists "${allCompootuersPath}/both.nix"
  ) (import "${allCompootuersPath}/both.nix");

  globalDefault = lib.optional (
    hasAllCompootuers && builtins.pathExists "${allCompootuersPath}/default.nix"
  ) (import "${allCompootuersPath}/default.nix");

  globalIso = lib.optional (
    hasAllCompootuers && builtins.pathExists "${allCompootuersPath}/iso.nix"
  ) (import "${allCompootuersPath}/iso.nix");
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
      inherit (sub) system src hostName;
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
        baseModules =
          [
            {
              networking.hostName = hostName;
              nixpkgs.pkgs = withSystem system ({ pkgs, ... }: pkgs);
            }
            localFlake.nixosModules.sane
            localFlake.nixosModules.nix-conf
          ]
          ++ globalBoth
          ++ lib.optional (src != null && builtins.pathExists "${src}/both.nix") (import "${src}/both.nix");

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
                # Overriding these to avoid warnings
                hashedPasswordFile = null;
                hashedPassword = null;
              };
            }
          ]
          ++ globalIso
          ++ lib.optional (src != null && builtins.pathExists "${src}/iso.nix") (import "${src}/iso.nix");

        nonIsoModules =
          globalDefault
          ++ lib.optional (src != null && builtins.pathExists "${src}/default.nix") (
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
            self
            system
            ;
        };
        modules = baseModules ++ lib.optionals iso isoModules ++ lib.optionals (!iso) nonIsoModules;
      }
    );
in
{
  options.allCompootuers.path = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = ''
      If set, points to a directory containing `both.nix`, `default.nix`, and/or
      `iso.nix` that should be applied to all hosts and systems.
    '';
  };

  options.compootuers.path = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = ''
      Path to the directory containing per-system subdirectories
      (each of which contains per-host directories).
    '';
  };

  config = {
    flake.nixosConfigurations = builtins.listToAttrs (
      builtins.concatLists (
        map (
          sub:
          let
            inherit (sub) hostName;
          in
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
