{
  config,
  lib,
  inputs,
  ...
}:
{
  options.genesis = {
    compootuers = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            hostname = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = ''
                Optional hostname. If null or not set, the submodule is ignored.
              '';
            };
          };
        }
      );
      description = ''
        A list of submodules, each with an optional hostname.
        Only those submodules that specify a hostname actually generate
        a NixOS configuration.
      '';
    };
  };
  config.flake.nixosConfigurations = builtins.listToAttrs (
    map (sub: {
      name = sub.hostname;
      value = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          inputs.nixos-facter-modules.nixosModules.facter
          inputs.nixembryo.nixosModules.default
          inputs.chaotic.nixosModules.default
          {
            facter.reportPath = ./facter.json;
            nixpkgs.config.allowUnfree = true;
          }
        ];
      };
    }) (lib.filter (sub: sub.hostname != null) config.genesis.compootuers)
  );
}
