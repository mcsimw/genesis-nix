{
  description = "common nix settings";
  outputs =
    {
      self,
      nixpkgs,
    }:
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      nixosModules =
        let
          defaultModules = {
            nix-config = ./modules/nix-conf.nix;
          };
        in
        defaultModules
        // {
          default.imports = builtins.attrValues defaultModules;
        };
    };
}
