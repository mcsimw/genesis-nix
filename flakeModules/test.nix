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
  allCompootuersPath =
    if config.allCompootuers.path == null then null else builtins.toPath config.allCompootuers.path;
  hasAllCompootuers = allCompootuersPath != null && builtins.pathExists allCompootuersPath;
  maybeFile = path: if builtins.pathExists path then path else null;
  globalBothFile = if hasAllCompootuers then maybeFile "${allCompootuersPath}/both.nix" else null;
  globalDefaultFile =
    if hasAllCompootuers then maybeFile "${allCompootuersPath}/default.nix" else null;
  globalIsoFile = if hasAllCompootuers then maybeFile "${allCompootuersPath}/iso.nix" else null;
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
        srcBothFile = if src != null then maybeFile "${src}/both.nix" else null;
        srcDefaultFile = if src != null then maybeFile "${src}/default.nix" else null;
        srcIsoFile = if src != null then maybeFile "${src}/iso.nix" else null;

        baseModules =
          [
            {
              networking.hostName = hostName;
              nixpkgs.pkgs = withSystem system ({ pkgs, ... }: pkgs);
            }

            localFlake.nixosModules.sane
            localFlake.nixosModules.nix-conf

          ]
          ++ lib.optional (globalBothFile != null) globalBothFile
          ++ lib.optional (srcBothFile != null) srcBothFile;

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
                # The cd-base sets these to "" so override them to avoid warnings:
                hashedPasswordFile = null;
                hashedPassword = null;
              };
            }
          ]
          ++ lib.optional (globalIsoFile != null) globalIsoFile
          ++ lib.optional (srcIsoFile != null) srcIsoFile;

        nonIsoModules =
          lib.optional (globalDefaultFile != null) globalDefaultFile
          ++ lib.optional (srcDefaultFile != null) srcDefaultFile;
        myModules = baseModules ++ lib.optionals iso isoModules ++ lib.optionals (!iso) nonIsoModules;

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
        modules = myModules;
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
