{ localFlake, ... }:
{
  config, lib, inputs, withSystem, self, ... }:
let
  modulesPath = "${inputs.nixpkgs.outPath}/nixos/modules";
  compootuersPath = lib.optionalString (config.compootuers.path != null)
    (builtins.toString config.compootuers.path);
  computedCompootuers = lib.optionals (compootuersPath != "") (
    let
      outerDir = builtins.readDir compootuersPath;
      systems = builtins.filter
        (system: (builtins.getAttr system outerDir).type == "directory")
        (builtins.attrNames outerDir);
    in
    builtins.concatLists (
      map (system:
        let
          systemPath = "${compootuersPath}/${system}";
          systemDir = builtins.readDir systemPath;
          hostDirs = builtins.filter
            (hostName: (builtins.getAttr hostName systemDir).type == "directory")
            (builtins.attrNames systemDir);
        in
          map (hostName: {
            inherit hostName system;
            src = builtins.toPath "${systemPath}/${hostName}";
          }) hostDirs
      ) systems
    )
  );
  configForSub =
    { sub, iso ? false, }:
    let
      inherit (sub) system src hostName;
    in
    withSystem system (
      { config, inputs', self', system, ... }:
      let
        baseModules =
          [ {
              networking.hostName = hostName;
              nixpkgs.pkgs = withSystem system ({ pkgs, ... }: pkgs);
            }
            localFlake.nixosModules.sane
            localFlake.nixosModules.nix-conf
          ]
          ++ lib.optional (src != null && builtins.pathExists "${src}/both.nix")
             (import "${src}/both.nix");
        isoModules =
          [ {
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
          ++ lib.optional (src != null && builtins.pathEx
