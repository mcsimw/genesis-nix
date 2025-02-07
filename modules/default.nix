{
  flake-parts-lib,
  inputs,
  ...
}:
let
  inherit (flake-parts-lib) importApply;
in
{
  flake.nixosModules = {
    compootuers = importApply ./nixos/compootuers.nix {
      flake = inputs;
    };
    sane = ./nixos/sane.nix;
    nix-conf = ./nixos/nix-conf.nix;
  };
}
