# nix-genesis

**nix-genesis** is a modular NixOS configuration framework built with Nix flakes. It leverages the power of [flake-parts](https://github.com/hercules-ci/flake-parts) for composable configuration. The repository is designed to provide a flexible and reproducible foundation for managing both full system configurations and installation ISO images.

## Features

- **Modular NixOS Configurations:** Easily compose and reuse NixOS modules.
- **Dual Configuration Outputs:** Generate configurations for both running systems and ISO images using the `compootuers` module.
- **Multi-System Support:** Built for multiple architectures:
  - `x86_64-linux`
  - `aarch64-linux`
  - `aarch64-darwin`
  - `x86_64-darwin`
- **Preconfigured Best Practices:** Comes with sensible defaults for networking, users, security, and system services.
- **Reproducible Builds with Flakes:** Harness the power of Nix flakes for reliable, reproducible system builds.

## Repository Structure

```plaintext
nix-genesis/
├── flake.nix           # Main flake file defining inputs and outputs using flake-parts
└── modules/
    ├── default.nix     # Imports and aggregates all NixOS modules
    └── nixos/
        ├── compootuers.nix  # Module for generating per-system and ISO configurations
        ├── sane.nix         # Provides sensible defaults for networking, hardware, and services
        └── nix-conf.nix     # Configures Nix-specific settings including flake pinning and experimental features
```

### flake.nix

The root `flake.nix` file sets up the project with:

- **Description & Outputs:** Declares the project description and outputs using `flake-parts`.
- **System Support:** Targets multiple architectures (`x86_64-linux`, `aarch64-linux`, etc.).
- **Dependencies:** Pulls in essential inputs such as `nixpkgs`, `flake-parts`, and `treefmt-nix`.

### Modules

- **default.nix:**
  Imports the NixOS modules and exposes them via the `flake.nixosModules` attribute set. It imports:

  - `compootuers.nix` – for generating both system and ISO configurations.
  - `sane.nix` – for establishing sane system defaults.
  - `nix-conf.nix` – for configuring Nix daemon settings and environment specifics.

- **nixos/compootuers.nix:**
  This module is the heart of the configuration. It accepts a list of computer configurations (each with options like `hostname`, `both`, `iso`, `src`, and `system`) and generates:

  - A system configuration for each host.
  - A corresponding ISO configuration (with an `-iso` suffix).

- **nixos/sane.nix:**
  Provides a base set of configurations for networking, graphics, users, security, and essential services to ensure a robust system setup.

- **nixos/nix-conf.nix:**
  Focuses on Nix-specific configuration. It handles:

  - Flake input pinning for reproducibility.
  - Nix daemon settings including trusted users and experimental features.
  - Default packages and environmental variables.

## Getting Started

### Prerequisites

- **Nix Installed:** Ensure that you have [Nix](https://nixos.org/download.html) installed with flake su



  This repository is designed to be used as a foundation for your own NixOS system configuration. To get started, you must create an external repository that includes `nix-genesis` as an input. Below is an example configuration demonstrating how to integrate `nix-genesis` into your setup. Here is an example configuration you can use:

```nix
{
  description = "";
  outputs =
    inputs:
    inputs.nix-genesis.inputs.flake-parts.lib.mkFlake { inherit inputs; } { 
      systems = [
        # include all of the arch types you plan on using in this flake
        "x86_64-linux"
      ];
      compootuers = [
        # You can define as many hosts as you please
        {
          hostname = "eldritch";
          src = ./eldritch;
          both = ./eldritch/both.nix;
          system = "x86_64-linux";
        }
        {
          hostname = "lemon";
          src = ./lemon;
          both = ./lemon/both.nix;
          system = "aarch64-linux";
        }
      ];
      imports = [
        inputs.nix-genesis.nixosModules.compootuers 
        inputs.nix-genesis.inputs.treefmt-nix.flakeModule 
        ./packages
      ];
    };
  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
    };
    nix-genesis = {
      type = "github";
      owner = "mcsimw";
      repo = "nix-genesis";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### Building a System Configuration

To build your NixOS system configuration, run:

```bash
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel
```

Replace `<hostname>` with the hostname defined in your `compootuers` configuration.

### Generating an ISO Image

The `compootuers` module automatically creates an ISO variant of the configuration. For a computer with hostname `myhost`, you can build the ISO image using:

```bash
nix build .#nixosConfigurations.myhost-iso.config.system.build.isoImage
```

### Customization

- **System Options:**
  In `nixos/compootuers.nix`, you can customize each computer configuration. Options include:

  - `hostname`: The system hostname.
  - `both`: Additional module paths that apply to both regular and ISO configurations.
  - `iso`: Extra modules specifically for ISO builds.
  - `src`: An optional path for source modules.
  - `system`: Target architecture or system type.

- **Extending Modules:**
  Add or modify modules in the `modules/` directory. Then, update `modules/default.nix` to import your new modules.

## Contributing

Contributions are welcome! If you encounter any issues or have suggestions for improvement, please open an issue or submit a pull request.

1. **Fork** the repository.
2. **Create** a new branch for your feature or bugfix.
3. **Commit** your changes.
4. **Open** a pull request describing your changes.

## License

This project is licensed under the [Unlicense License](LICENSE).

## Acknowledgments

- [NixOS](https://nixos.org) for the powerful NixOS ecosystem.
- [flake-parts](https://github.com/hercules-ci/flake-parts) for an elegant way to manage Nix flakes.

## Contact

For questions, suggestions, or support, please open an issue in this repository or contact [[maor@mcsimw.com](mailto\:maor@mcsimw.com)].

---

Happy Nix-ing!


