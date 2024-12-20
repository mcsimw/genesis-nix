{
  description = "common nix settings";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.treefmt-nix.flakeModule ];
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        { pkgs, system, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              deadnix.enable = true;
              statix.enable = true;
            };
          };
        };
      flake = {
        nixosModules =
          let
            defaultModules = {
              nix-conf = ./modules/nixos/nix-conf.nix;
              nixos-conf = ./modules/nixos/nixos-conf.nix;
              root-clean = ./modules/nixos/root-clean.nix;
              impermanence = ./modules/nixos/impermanence.nix;
              home-manager = ./modules/nixos/home-manager.nix;
            };
          in
          defaultModules
          // {
            default.imports = builtins.attrValues defaultModules;
          };
      };
    };
}
