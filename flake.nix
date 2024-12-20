{
  description = "common nix settings";
  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
      nixosModules =
        let
          defaultModules = {
            nix-conf = ./modules/nixos/nix-conf.nix;
            nixos-conf = ./modules/nixos/nixos-conf.nix;
            root-clean = ./modules/nixos/root-clean.nix;
          };
        in
        defaultModules
        // {
          default.imports = builtins.attrValues defaultModules;
        };
    };
}
