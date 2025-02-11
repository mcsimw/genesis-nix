{lib, ...}: {
  flake.lib.dirToAttrs = dir: lib.mapAttrs' (name: value: lib.nameValuePair (lib.removeSuffix ".nix" name) (dir + "/${name}")) (builtins.readDir dir);
}
