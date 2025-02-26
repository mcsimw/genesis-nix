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
  ####################################################################
  # 1) Path to nixpkgs modules (used for ISO imports)
  ####################################################################
  modulesPath = "${inputs.nixpkgs.outPath}/nixos/modules";

  ####################################################################
  # 2) compootuers.perSystem and compootuers.allSystems
  ####################################################################
  perSystemPath = if config.compootuers.perSystem == null
    then null
    else builtins.toPath config.compootuers.perSystem;

  allSystemsPath = if config.compootuers.allSystems == null
    then null
    else builtins.toPath config.compootuers.allSystems;

  hasPerSystem  = perSystemPath  != null && builtins.pathExists perSystemPath;
  hasAllSystems = allSystemsPath != null && builtins.pathExists allSystemsPath;

  ####################################################################
  # 3) Build the list of (system, host) only if hasPerSystem is true
  ####################################################################
  computedCompootuers = builtins.concatLists (
    lib.optionals hasPerSystem [
      builtins.concatLists (
        map (system: 
          let
            systemPath = "${perSystemPath}/${system}";
            hostNames  = builtins.attrNames (builtins.readDir systemPath);
          in
          # each element is itself a list of hosts
          map (hostName: {
            inherit hostName system;
            src = builtins.toPath "${systemPath}/${hostName}";
          }) hostNames
        )
        (builtins.attrNames (builtins.readDir perSystemPath))
      )
    ]
  );

  # At least one (system, host) => hasHosts
  hasHosts = (builtins.length computedCompootuers) > 0;

  ####################################################################
  # 4) Maybe-file helper
  ####################################################################
  maybeFile = path: if builtins.pathExists path then path else null;

  ####################################################################
  # 5) Global modules from allSystemsPath, only if hosts exist
  ####################################################################
  globalBothFile    = if hasHosts && hasAllSystems then maybeFile "${allSystemsPath}/both.nix"    else null;
  globalDefaultFile = if hasHosts && hasAllSystems then maybeFile "${allSystemsPath}/default.nix" else null;
  globalIsoFile     = if hasHosts && hasAllSystems then maybeFile "${allSystemsPath}/iso.nix"     else null;

  ####################################################################
  # 6) Build a NixOS configuration for each (hostName, system)
  ####################################################################
  configForSub =
    { sub, iso ? false }:
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
        # Local modules for this particular host
        srcBothFile    = if src != null then maybeFile "${src}/both.nix"    else null;
        srcDefaultFile = if src != null then maybeFile "${src}/default.nix" else null;
        srcIsoFile     = if src != null then maybeFile "${src}/iso.nix"     else null;

        # Base modules always used
        baseModules =
          [
            {
              network

