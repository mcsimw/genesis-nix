{ lib, config, inputs, withSystem, system, ... }:
{
  imports = lib.optional (config.readOnlyNixpkgs inputs.nixpkgs.nixosModules.readOnlyPkgs);
  options = {
    readOnlyNixpkgs = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "If true, import the readOnlyPkgs module to override the default nixpkgs configuration.";
    };
  };
  config = lib.mkIf config.readOnlyNixpkgs {
    nixpkgs.pkgs = withSystem system ({ pkgs, ... }: pkgs);
  };
}
