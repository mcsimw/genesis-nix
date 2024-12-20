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
    programs.command-not-found.enable = false;
    documentation = {
      enable = lib.mkDefault true;
      man.enable = lib.mkDefault true;
      doc.enable = lib.mkForce false;
      nixos.enable = lib.mkForce false;
      info.enable = lib.mkForce false;
    };
    nixpkgs.overlays = lib.optional (inputs ? "nix") inputs.nix.overlays.default;
    environment.variables.NIXPKGS_CONFIG = lib.mkForce "";
    nix = {
      registry = lib.listToAttrs (
        map (name: lib.nameValuePair name { flake = inputs.${name}; }) config.nix.inputsToPin
      );
      nixPath = [ "nixpkgs=flake:nixpkgs" ];
      channel.enable = false;
      settings = {
        "flake-registry" = "/etc/nix/registry.json";
      } // (import ../../nix-settings.nix { inherit pkgs; });
    };
  };
}
