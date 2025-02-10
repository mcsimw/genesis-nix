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
    test = importApply ./nixos/test.nix {
      flake = inputs;
    };
    test1 = importApply ./nixos/test1.nix {
      flake = inputs;
    };
    test2 = importApply ./nixos/test2.nix {
      flake = inputs;
    };
    test3 = importApply ./nixos/test3.nix {
      flake = inputs;
    };
    sane = ./nixos/sane.nix;
    nix-conf = ./nixos/nix-conf.nix;
    fakeFileSystems = importApply ./nixos/fakeFileSystems {
      flake = inputs;
    };
  };
}
