{ lib, ... }:
{
  nix.settings = {
    allow-import-from-derivation = false;
    connect-timeout = 5;
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
