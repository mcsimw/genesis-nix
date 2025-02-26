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

  # If compootuers.path is set, capture it as a string
  compootuersPath = lib.optionalString (config.compootuers.path != null) (
    builtins.toString config.compootuers.path
  );

  # Helper: check if a path exists
  pathExists = builtins.pathExists or (_p: false);

  # Read directory entries if compootuersPath is non-empty & exists
  compootuersEntries =
    if compootuersPath != "" && pathExists compootuersPath then
      builtins.readDir compootuersPath
    else
      { };

  # Filter out non-directories, and exclude "allSystems"
  systemNames = builtins.filter (
    name: compootuersEntries.${name}.type == "directory" && name != "allSystems"
  ) (builtins.attrNames compootuersEntries);

  # Special "allSystems" directory
  allSystemsPath = "${compootuersPath}/allSystems";
  hasAllSystems = pathExists allSystemsPath;

  # Build (system, hostName) pairs from subdirectories
  computedCompootuers = lib.optionals (compootuersPath != "") (
    builtins.concatLists (
      map (
        systemName:
        let
          systemPath = "${compootuersPath}/${systemName}";
          systemEntries = builtins.readDir systemPath;
          # Again, only directories for host directories
          hostNames = builtins.filter (hn: systemEntries.${hn}.type == "directory") (
            builtins.attrNames systemEntries
          );
        in
        map (hostName: {
          inherit hostName;
          system = systemName;
          src = builtins.toPath "${systemPath}/${hostName}";
        }) hostNames
      ) systemNames
    )
  );

  # Helper: only import a file if it actually exists
  importIfExists = path: if pathExists path then [ (import path) ] else [ ];

  # Generate a NixOS configuration for a sub { hostName, system, src }
  configForSub =
    {
      sub,
      iso ? false,
    }:
    let
      inherit (sub) system src hostName;

      # Base modules (always included)
      baseModules =
        [
          {
            networking.hostName = hostName;
            nixpkgs.pkgs = withSystem system ({ pkgs, ... }: pkgs);
          }
          localFlake.nixosModules.sane
          localFlake.nixosModules.nix-conf
        ]
        # Optional host-level both.nix
        ++ importIfExists "${src}/both.nix"
        # Optional allSystems/both.nix
        ++ (if hasAllSystems then importIfExists "${allSystemsPath}/both.nix" else [ ]);

      # Modules to add if `iso = true`
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
              hashedPasswordFile = null;
              hashedPassword = null;
            };
          }
        ]
        # Optional host-level iso.nix
        ++ importIfExists "${src}/iso.nix"
        # Optional allSystems/iso.nix
        ++ (if hasAllSystems then importIfExists "${allSystemsPath}/iso.nix" else [ ]);

      # Modules to add if `iso = false`
      nonIsoModules =
        # Optional host-level default.nix
        importIfExists "${src}/default.nix"
        # Optional allSystems/default.nix
        ++ (if hasAllSystems then importIfExists "${allSystemsPath}/default.nix" else [ ]);
    in
    withSystem system (
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
            self
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
    description = ''
      Path to your compootuers folder, containing system directories
      and (optionally) an `allSystems` folder with .nix files that
      get applied to all systems.
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
