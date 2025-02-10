{
  description = "Nix Genesis - Custom Flake Utilities";

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

  outputs =
    inputs@{ flake-parts, ... }:
    let
      # Load flake-parts' library
      inherit (flake-parts) lib;

      # Define mkFlake function so users can call it via an alias
      inherit (lib) mkFlake;
    in
    # Use flake-parts' mkFlake to structure outputs properly
    lib.mkFlake { inherit inputs; } {
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

      imports = [
        inputs.treefmt-nix.flakeModule
        ./modules
      ];

      # Expose mkFlake under an alias
      flake = {
        yooo = mkFlake;
      };
    };
}
