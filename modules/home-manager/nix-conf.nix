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
    nix = {
      registry = lib.listToAttrs (
        map (name: lib.nameValuePair name { flake = inputs.${name}; }) config.nix.inputsToPin
      );
      settings = {
        "flake-registry" = "${config.xdg.configHome}/nix/registry.json";
      } // (import ../nix-settings.nix { inherit pkgs; });
    };
  };
}
