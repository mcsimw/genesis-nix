{
  description = "nix sane defaults";
  inputs = {
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
  };
  outputs =
    {
      self,
      treefmt-nix,
      nixpkgs,
      systems,
    }:
    let
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });
      nixosModules =
        let
          defaultModules = {
            nix-conf = ./modules/nixos/nix-conf.nix;
            sane = ./modules/nixos/sane.nix;
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
}
