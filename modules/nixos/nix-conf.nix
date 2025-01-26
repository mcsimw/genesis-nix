{
  lib,
  config,
  pkgs,
  inputs ? throw "Pass inputs to specialArgs or extraSpecialArgs",
  ...
}:
{
  imports = lib.optional (inputs ? "lix-module") inputs.lix-module.nixosModules.default;
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
    nixpkgs.overlays = lib.optional (
      inputs ? "nix" && !(inputs ? "lix-module")
    ) inputs.nix.overlays.default;
    nix = {
      trusted-users = [ "@wheel" ];
      allowed-users = lib.mapAttrsToList (_: u: u.name) (
        lib.filterAttrs (_: user: user.isNormalUser) config.users.users
      );
      registry = lib.listToAttrs (
        map (name: lib.nameValuePair name { flake = inputs.${name}; }) config.nix.inputsToPin
      );
      nixPath = [ "nixpkgs=flake:nixpkgs" ];
      channel.enable = false;
      settings = {
        "flake-registry" = "/etc/nix/registry.json";
      } // (import ../nix-settings.nix { inherit pkgs; });
    };
  };
}
