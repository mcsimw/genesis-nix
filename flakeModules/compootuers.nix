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
  perSystemPath =
    if config.compootuers.perSystem == null then null else builtins.toPath config.compootuers.perSystem;
  allSystemsPath =
    if config.compootuers.allSystems == null then
      null
    else
      builtins.toPath config.compootuers.allSystems;
  hasPerSystem = perSystemPath != null && builtins.pathExists perSystemPath;
  hasAllSystems = allSystemsPath != null && builtins.pathExists allSystemsPath;
  computedCompootuers =
    if hasPerSystem then
      builtins.concatLists (
        map (
          system:
          let
            systemPath = "${perSystemPath}/${system}";
            hostNames = builtins.attrNames (builtins.readDir systemPath);
          in
          map (hostName: {
            inherit hostName system;
            src = builtins.toPath "${systemPath}/${hostName}";
          }) hostNames
        ) (builtins.attrNames (builtins.readDir perSystemPath))
      )
    else
      [ ];
  hasHosts = (builtins.length computedCompootuers) > 0;
  maybeFile = path: if builtins.pathExists path then path else null;
  globalBothFile = if hasHosts && hasAllSystems then maybeFile "${allSystemsPath}/both.nix" else null;
  globalDefaultFile =
    if hasHosts && hasAllSystems then maybeFile "${allSystemsPath}/default.nix" else null;
  globalIsoFile = if hasHosts && hasAllSystems then maybeFile "${allSystemsPath}/iso.nix" else null;
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
            (
              { config, lib, ... }:
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
                networking.hostId = lib.mkForce (
                  builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName)
                );
              }
            )
          ]
          ++ lib.optional (globalIsoFile != null) globalIsoFile
          ++ lib.optional (srcIsoFile != null) srcIsoFile;
        nonIsoModules =
          [
            (
              { lib, config, ... }:
              {
                networking.hostId = lib.mkDefault (
                  builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName)
                );
              }
            )
          ]
          ++ lib.optional (globalDefaultFile != null) globalDefaultFile
          ++ lib.optional (srcDefaultFile != null) srcDefaultFile;
        finalModules = baseModules ++ lib.optionals iso isoModules ++ lib.optionals (!iso) nonIsoModules;
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
        modules = finalModules;
      }
    );
in
{
  options.compootuers = {
    perSystem = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        If set, this path must contain subdirectories named after each "system",
        which contain subdirectories named after each "host".
        E.g. `$perSystem/x86_64-linux/myhost/default.nix`.
      '';
    };
    allSystems = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        If set, this path can contain `both.nix`, `default.nix`, and/or `iso.nix`
        which are applied to all systems/hosts (but only if "perSystem" actually
        has at least one valid host).
      '';
    };
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
