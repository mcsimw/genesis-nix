# Genesis Module

The **Genesis Module** is a NixOS flake module designed to simplify the configuration of multiple NixOS machines. It leverages a list of computer configurations, each defined by hostname, system architecture, and source of configuration, to automatically generate corresponding NixOS configurations.

## Overview

The Genesis Module provides:

- A list option `genesis.compootuers` where you can define multiple hosts.
- Automatic generation of `nixosConfigurations` from the provided hosts configuration.
- Integration with [flake-parts](https://github.com/hercules-ci/flake-parts) and other Nix flakes for a modular and maintainable setup.

## Prerequisites

- Basic familiarity with [NixOS](https://nixos.org) and the [Flakes](https://nixos.wiki/wiki/Flakes) feature.
- A working NixOS setup using flakes.
- [flake-parts](https://github.com/hercules-ci/flake-parts) integrated into your configuration.
- The Genesis Module imported from its source repository (e.g., GitHub).

## Configuration Options

The Genesis Module accepts a list of computer definitions under `genesis.compootuers`, where each entry includes:

- `hostname`: (optional) The hostname of the machine. If omitted or set to `null`, the configuration for that entry is ignored.
- `src`: The path to the configuration file or directory for the host.
- `system`: The target system architecture (default: `"x86_64-linux"`).

## Example Setup

Below is a simplified example of how to initialize and use the Genesis Module within your own `flake.nix`:

```nix
{
  description = "Your new nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    NixCastratumStillbirth.url = "github:mcsimw/NixCastratumStillbirth";
    # Add other required inputs...
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      # Define the list of computers you want to configure
      genesis.compootuers = [
        {
          hostname = "nixos";
          src = ./.;
          # Optional: system = "x86_64-linux";  # Defaults to "x86_64-linux"
        }
      ];

      # Additional per-system configurations (optional)
      perSystem.treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          deadnix.enable = true;
          statix.enable = true;
          dos2unix.enable = true;
        };
        settings.formatter = {
          deadnix.priority = 1;
          statix.priority = 2;
          nixfmt.priority = 3;
          dos2unix.priority = 4;
        };
      };

      # Import the Genesis Module from your chosen source
      imports = [
        inputs.NixCastratumStillbirth.nixosModules.genesis
      ];
    };
}

