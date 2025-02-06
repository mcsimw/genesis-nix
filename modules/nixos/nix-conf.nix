{
  lib,
  config,
  pkgs,
  inputs ? throw "Pass inputs to specialArgs or extraSpecialArgs",
  ...
}:
{
  options = with lib; {
    nix.inputsToPin = mkOption {
      type = with types; listOf str;
      default = [ "nixpkgs" ];
      example = [
        "nixpkgs"
        "nixpkgs-master"
      ];
      description = ''
        Names of flake inputs to pin
      '';
    };
  };
  config = {
    environment.variables.NIXPKGS_CONFIG = lib.mkForce "";
    system = {
      tools.nixos-option.enable = false;
      rebuild.enableNg = true;
    };
    nix = {
      registry = lib.listToAttrs (
        map (name: lib.nameValuePair name { flake = inputs.${name}; }) config.nix.inputsToPin
      );
      nixPath = [ "nixpkgs=flake:nixpkgs" ];
      channel.enable = false;
      settings = {
        trusted-users = [ "@wheel" ];
        allowed-users = lib.mapAttrsToList (_: u: u.name) (
          lib.filterAttrs (_: user: user.isNormalUser) config.users.users
        );
        "flake-registry" = "/etc/nix/registry.json";
      } // (import ../nix-settings.nix { inherit pkgs; });
    };
  };
}
