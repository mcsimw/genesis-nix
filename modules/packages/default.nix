{ flake, ... }:
{
  config,
  inputs,
  ...
}:
{
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          flake.emacs-overlay.overlays.default
        ];
        config.allowUnfree = true;
      };
    };
}
