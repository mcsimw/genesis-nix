# Genesis Module

The **Genesis Module** is a NixOS flake module designed to simplify the configuration of multiple NixOS machines. It leverages a list of computer configurations, each defined by hostname, system architecture, and source of configuration, to automatically generate corresponding NixOS configurations.

## Features

- **Multi-Host Configuration**: Define configurations for multiple hosts using the `genesis.compootuers` option.
- **Automatic Configuration Generation**: Automatically create `nixosConfigurations` for all defined hosts.
- **Modular Integration**: Works seamlessly with [flake-parts](https://github.com/hercules-ci/flake-parts) and other flakes.
- **Sane Defaults**: Applies reasonable default settings to all hosts for usability, security, and consistency.
- **Support for Ephemeral Root**: Easily configure ZFS-based root filesystems with impermanence.

## Sane Defaults

The Genesis Module applies a set of sensible default settings to every host to ensure consistency and reduce configuration overhead. These include:

- **Networking**:
  - DHCP is enabled by default.
  - `systemd-networkd` is used for managing network configurations.

- **Hardware**:
  - 32-bit graphics support is enabled to improve compatibility.
  - User accounts are immutable by default, meaning changes to users and groups are managed declaratively.

- **Security**:
  - Polkit (authorization framework) is enabled.
  - Real-time kit (rtkit) is enabled when PipeWire is used for audio.

- **Services**:
  - Disk trimming (`fstrim`) is enabled for maintaining SSD performance. This will trim whatever (filesystem && drive type) it support, no reason not to keep enabled. Drives using filesystems like zfs will not utilize this feature (they have their own implementation), but for example the vfat esp partiition actually utilizes it.
  - PulseAudio is forcibly disabled in favor of alternative audio systems like PipeWire.
  - EarlyOOM is enabled to gracefully handle out-of-memory situations.
  - UDisks2 is enabled for disk management.
  - D-Bus implementation is set to "broker" for improved performance.
  - If ZFS is enabled:
    - Automatic scrub and trim are performed daily for data integrity and performance.

- **Environment**:
  - Minimal environment variables are set for clean Nixpkgs configurations.
  - No global default packages are installed.

- **Programs**:
  - `direnv` is enabled for project-specific environment management.
  - Vim is enabled and set as the default editor.
  - Git is always enabled, with Git LFS support for handling large files.

- **Documentation**:
  - Basic system documentation and man pages are enabled.
  - Additional documentation (`doc`, `info`, `nixos`) is disabled to avoid clutter.

- **Boot**:
  - Systemd is used in the initrd for faster boot times and better compatibility.
  - ZFS root import is disabled by default for stability in certain setups.

## Example Usage

Below is an example of how to initialize and use the Genesis Module in your `flake.nix`:

```nix
{
  description = "Your new nix config";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    NixCastratumStillbirth.url = "github:mcsimw/NixCastratum";
  };
  outputs = inputs: 
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ]; # Put here all the arch types that your flake must support
      genesis.compootuers = [
        {
          hostname = "nixos"; # I hope I do not need to explain this
          /* This will read default.nix, and in there your configuration will reside
          ( you can of course point to any file or directory ) */
          src = ./.;
          system = "aarch64-linux" # Defaults to "x86_64-linux" if not defined
        }
      ];
      imports = [
        inputs.NixCastratum.nixosModules.genesis
      ];
    };
}
