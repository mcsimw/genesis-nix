{
  description = "Description for the project";
  outputs =
    inputs:
    let
      mkFlake = inputs.flake-parts.lib.mkFlake { inherit inputs; };
      genesisOut = mkFlake {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
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
        imports = [
          inputs.treefmt-nix.flakeModule
          ./modules
        ];
      };
    in
    genesisOut
      // {
        flake = {
          yooo = mkFlake;
        };
      };
  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
    };
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
    impermanence = {
      type = "github";
      owner = "nix-community";
      repo = "impermanence";
    };
    disko = {
      type = "github";
      owner = "nix-community";
      repo = "disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
