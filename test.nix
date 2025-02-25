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
  compootuersPath = lib.optionalString (config.compootuers.path != null) (
    builtins.toString config.compootuers.path
  );
  globalDefault = lib.optional (
    compootuersPath != "" && builtins.pathExists "${compootuersPath}/default.nix"
  ) (import "${compootuersPath}/default.nix");
  globalBoth = lib.optional (
    compootuersPath != "" && builtins.pathExists "${compootuersPath}/both.nix"
  ) (import "${compootuersPath}/both.nix");
  globalIso = lib.optional (
    compootuersPath != "" && builtins.pathExists "${compootuersPath}/iso.nix"
  ) (import "${compootuersPath}/iso.nix");
  computedCompootuers = lib.optionals (compootuersPath != "") (
    builtins.concatLists (
      map (system:
        let
          systemPath = "${compootuersPath}/${system}";
          hostNames = builtins.attrNames (
            builtins.filterAttrs (name: value: value.isDir)
              (builtins.readDir systemPath)
          );
        in
        map (hostName: {
          inherit hostName system;
          src = builtins.toPath "${systemPath}/${hostName}";
        }) hostNames
      ) (builtins.attrNames (
        builtins.filterAttrs (name: value: value.isDir)
          (builtins.readDir compootuersPath)
      ))
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
              # For some reason the installation-cd-base.nix sets these to "",
              # which may stop initialPassword from working.
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
            self
            system;
        };
        modules =
          baseModules
          ++ lib.optionals (globalBoth != null) globalBoth
          ++ lib.optionals (!iso && (globalDefault != null)) globalDefault
          ++ lib.optionals (iso && (globalIso != null)) globalIso
          ++ lib.optionals iso isoModules
          ++ lib.optionals (!iso) nonIsoModules;
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
