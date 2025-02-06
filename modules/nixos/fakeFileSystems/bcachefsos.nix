{ lib, config, ... }:
let
  cfg = config.fakeFileSystems.nix;
in
{
  config = lib.mkIf (cfg.template == "bcachefsos") (
    import ./templates/bcachefsos.nix { inherit (cfg) device diskName; }
  );
}
