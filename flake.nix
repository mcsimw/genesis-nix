{
  description = "common nix settings";
  outputs = {
    self,
  }: {
    nixosModules = let
      defaultModules = {
        channels-to-flakes = ./modules/channels-to-flakes.nix;
        nix-config = ./modules/nix-conf.nix;
      };
    in
      defaultModules
      // {
        default.imports = builtins.attrValues defaultModules;
      };
  };
}
