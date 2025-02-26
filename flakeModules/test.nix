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

  # Path to compootuers directory if set
  compootuersPath = lib.optionalString (config.compootuers.path != null) (
    builtins.toString config.compootuers.path
  );

  # Helper: check if a path exists
  pathExists = builtins.pathExists or (_p: false);

  # If compootuersPath is non-empty, read directory entries
  compootuersEntries =
    if compootuersPath != "" && pathExists compootuersPath then
      builtins.readDir compootuersPath
    else
      { };

  # For each entry in compootuersPath, keep only directories (type == "directory")
  # and exclude "allSystems" special folder from normal systems.
  systemNames = builtins.filter (
    name: compootuersEntries.${name}.type == "directory" && name != "allSystems"
  ) (builtins.attrNames compootuersEntries);

  # The "allSystems" directory
  allSystemsPath = "${compootuersPath}/allSystems";
  hasAllSystems = pathExists allSystemsPath;

  # Build our list of (system, hostName) pairs.
  computedCompootuers = lib.optionals (compootuersPath != "") (
    builtins.concatLists (
      map (
        systemName:
        let
          systemPath = "${compootuersPath}/${systemName}";
          systemEntries = builtins.readDir systemPath;
          # For the system directory, again keep only directories
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

  # Helper function that imports a file in a directory, but only if the file exists
  importIfExists = path: if pathExists path then [ (import path) ] else [ ];

  configForSub =
    {
      sub,
      iso ? false,
    }:
    let
      inherit (sub) system src hostName;

      # Each system gets "both.nix" from the system/host directory, plus
      # "both.nix" from allSystems (if it exists).
      baseModules =
        [
          {
            networking.hostName = hostName;
            nixpkgs.pkgs = withSystem system ({ pkgs, ... }: pkgs);
          }
          localFlake.nixosModules.sane
          localFlake.nixosModules.nix-conf
        ]
        # host-specific "both.nix"?
        ++ importIfExists "${src}/both.nix"
        # allSystems "both.nix" if present?
        ++ (if hasAllSystems then importIfExists "${allSystemsPath}/both.nix" else [ ]);

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
              # The next two lines let you override that default cleanly
              hashedPasswordFile = null;
              hashedPassword = null;
            };
          }
        ]
        # host-specific "iso.nix"?
        ++ importIfExists "${src}/iso.nix"
        # allSystems "iso.nix"?
        ++ (if hasAllSystems then importIfExists "${allSystemsPath}/iso.nix" else [ ]);

      nonIsoModules =
        # host-specific "default.nix" if it exists
        importIfExists "${src}/default.nix"
        # plus allSystems "default.nix"
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
            inherit sub hostName;
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
