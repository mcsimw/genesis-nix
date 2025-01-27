{ lib, flake, ... }:
{ config, inputs, ... }:

{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.emacs.overlays.default
        ];
        config.allowUnfree = true;
      };
      stage1 = {
        #        nix = callPackage ./nix-overrides/default.nix { };
      };
      finalPackages =
        (flake.wrapper-manager.lib {
          pkgs = pkgs // stage1;
          modules = [
            ./wrapper-manager/chrome/default.nix
          ];
        }).config.build.packages;
    in
    {
      # Flake outputs added by this module:
      packages = finalPackages;
    };
}
