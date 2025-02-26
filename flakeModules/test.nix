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

  # Helper: check if a path/directory exists
  pathExists = builtins.pathExists or (_p: false);

  # Returns true if `path` is a regular file (not a directory, symlink, etc.)
  isRegularFile =
    path:
    let
      dir = builtins.dirOf path;
      base = builtins.baseNameOf path;
    in
    pathExists dir && (builtins.readDir dir ? base) && builtins.readDir dir.${base}.type == "regular";

  # Only import if the path is a file
  importIfFile = path: if isRegularFile path then [ (import path) ] else [ ];

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
          # For each system directory, only keep subdirs as host directories
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

  # Generate a NixOS configuration for a sub { hostName, system, src }
  configForSub =
    {
      sub,
      iso ? false,
    }:
    let
      inherit (sub) system src hostName;

      baseModules =
        [
          {
            networking.hostName = hostName;
            nixpkgs.pkgs = withSystem system ({ pkgs, ... }: pkgs);
          }
          localFlake.nixosModules.sane
          localFlake.nixosModules.nix-conf
        ]
        # Host-level both.nix
        ++ importIfFile "${src}/both.nix"
        # allSystems/both.nix
        ++ (if hasAllSystems then importIfFile "${allSystemsPath}/both.nix" else [ ]);

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
        # Host-level iso.nix
        ++ importIfFile "${src}/iso.nix"
        # allSystems/iso.nix
        ++ (if hasAllSystems then importIfFile "${allSystemsPath}/iso.nix" else [ ]);

      nonIsoModules =
        # Host-level default.nix
        importIfFile "${src}/default.nix"
        # allSystems/default.nix
        ++ (if hasAllSystems then importIfFile "${allSystemsPath}/default.nix" else [ ]);

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
