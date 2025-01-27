{ lib, ... }:
{ config, inputs, ... }:

{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          (_final: prev: {
            gnome-keyring = prev.gnome-keyring.overrideAttrs (old: {
              configureFlags = (lib.remove "--enable-ssh-agent" old.configureFlags or [ ]) ++ [
                "--disable-ssh-agent"
              ];
            });
          })
        ];
        config = {
          # Example allowInsecure predicate
          allowInsecurePredicate =
            pkg:
            let
              pname = lib.getName pkg;
              inWhitelist = builtins.elem pname [ "nix" ];
            in
            if inWhitelist then lib.warn "Allowing insecure package: ${pname}" true else false;
          allowUnfreePredicate =
            pkg:
            let
              pname = lib.getName pkg;
              byName = builtins.elem pname [
                "cnijfilter2"
                "drawio"
                "google-chrome"
                "hplip"
                "nvidia-settings"
                "nvidia-x11"
                "samsung-UnifiedLinuxDriver"
                "slack"
                "steam"
                "steam-original"
                "steam-unwrapped"
                "vscode"
              ];
              byLicense = builtins.elem (pkg.meta.license.shortName or "") [
                "CUDA EULA"
                "bsl11"
                "obsidian"
              ];
            in
            if byName || byLicense then lib.warn "Allowing unfree package: ${pname}" true else false;
        };
      };
      stage1 = {
        #        nix = callPackage ./nix-overrides/default.nix { };
      };
      finalPackages =
        (inputs.wrapper-manager.lib {
          pkgs = pkgs // stage1;
          modules = [
            ./wrapper-manager/chrome/default.nix
          ];
        }).config.build.packages;
    in
    {
      # Flake outputs added by this module:
      packages = finalPackages;
    };
}
