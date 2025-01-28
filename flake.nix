{
  description = "this is something:(";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wrapper-manager = {
      url = "github:viperML/wrapper-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem.treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          deadnix.enable = true;
          statix.enable = true;
          dos2unix.enable = true;
        };
      };
      flake.nixosModules =
        let
          defaultModules = {
            nix-conf = ./modules/nixos/nix-conf.nix;
            sane = ./modules/nixos/sane.nix;
            impermanence = ./modules/nixos/impermanence.nix;
            home-manager = ./modules/nixos/home-manager.nix;
          };
        in
        defaultModules
        // {
          default.imports = builtins.attrValues defaultModules;
          genesis =
            {
              withSystem,
              self,
              flake-parts-lib,
              ...
            }:
            flake-parts-lib.importApply ./modules/nixos/genesis.nix {
              localFlake = self;
              inherit withSystem;
            };
          fakeFileSystems =
            { lib, ... }:
            lib.modules.importApply ./modules/nixos/fakeFileSystems {
              flake = inputs;
            };
        };
    };
}
