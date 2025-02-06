{
  lib,
  config,
  flake,
  ...
}:
let
  cfg = config.fakeFileSystems.nix;
in
{
  imports = [
    flake.impermanence.nixosModules.impermanence
  ];
  config = lib.mkIf (cfg.template == "bcachefsos") (
    import ./templates/bcachefsos.nix { inherit (cfg) device diskName swapSize; }
  );
}
