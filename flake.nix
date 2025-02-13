{
  description = "nix-genesis";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts = {
      type = "github";
      owner = "hercules-ci";
      repo = "flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      type = "github";
      owner = "numtide";
      repo = "treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      {
        lib,
        config,
        self,
        ...
      }:
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
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
        imports = with inputs; [
          treefmt-nix.flakeModule
          ./lib.nix
        ];
        flake = {
          nixosModules = self.lib.dirToAttrs ./modules/nixosModules;
          flakeModules.compootuers = lib.modules.importApply ./modules/flakeModules/compootuers.nix {
            localFlake = self;
          };
        };
      }
    );
}
