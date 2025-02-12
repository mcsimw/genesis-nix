# nix-genesis

**nix-genesis** is a modular Nix flake for generating and managing reproducible NixOS configurations across multiple architectures. By leveraging [flake-parts](https://github.com/hercules-ci/flake-parts) for modularity and integrating formatting tools such as [treefmt-nix](https://github.com/numtide/treefmt-nix), this repository provides a streamlined workflow for creating and maintaining both system and ISO configurations.

---

## Overview

nix-genesis is designed to generate host-specific NixOS configurations with a clear separation of concerns:

- **Host Configuration:** Uses the `compootuers` module to automatically detect and build configurations for multiple hosts based on a prescribed directory structure.
- **System Defaults:** The `sane.nix` module provides a set of carefully selected defaults for networking, hardware, services, programs, and boot options to ensure a stable and predictable system.
- **Nix Configuration:** The `nix-conf.nix` module refines the Nix package manager environment, pinning flake inputs, defining registry behavior, and enabling crucial experimental features.

Together, these modules help you maintain reproducible, secure, and easy-to-customize configurations for your systems.

---

## Repository Structure

```
├── flake.lock            # Ignored by git, does not exist🙂, don't worry about it 🙂 
├── flake.nix             # Main flake file integrating modules and outputs
├── lib.nix               # Utility functions used across the flake
├── LICENSE               # License file
├── .gitignore            # Git ignore rules
└── modules
    ├── compootuers.nix   # Module for host-specific configurations
    └── nixosModules
         ├── nix-conf.nix  # Nix configuration module (nix-conf)
         └── sane.nix      # Default configuration module (sane)
```

---

## Module Details

### sane.nix

The `sane.nix` module applies essential configurations that improve reliability and security:

- **Networking:**

  - Uses `systemd-networkd` by default because it is better.
  - Enables  DHCP is enabled by default.
  - Generates a stable `hostId` based on the hostname for ZFS consistency.

- **Hardware & Services:**

  - Enables 32-bit graphics support.
  - Configures automatic `fstrim`, `earlyoom`, and `udisks2` services.
  - Sets up automatic ZFS maintenance (auto-scrub and trim) if ZFS is detected.

- **User & Program Settings:**

  - Disables mutable user accounts by default.
  - Enables essential programs such as `direnv`, `vim` (default editor), and `git` with LFS support by default are enabled.

- **Boot & Documentation:**

  - Enables `initrd.systemd` by defalut  because it is better. 
  - Ensures essential system documentation is available while keeping unnecessary docs disabled.

### nix-conf.nix

The `nix-conf.nix` module customizes the behavior of the Nix package manager:

- **Flake Inputs Pinning:**

  - Introduces `nix.inputsToPin`, which ensures critical flake inputs like `nixpkgs` remain locked for stability.

- **Nix Settings:**

  - Enforces sandboxing and security settings.
  - Enables experimental features like `nix-command`, `flakes`, and `auto-allocate-uids`.
  - Configures trusted users and caching settings to optimize builds.

---

## Using nix-genesis in Your Configuration

To use nix-genesis in your own flake, reference it in your `flake.nix`:

```nix
{
  description = "";
  outputs =
    inputs:
    inputs.nix-genesis.mkFlake { inherit inputs; } {
      perSystem.treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
          deadnix.enable = true;
          statix.enable = true;
          dos2unix.enable = true;
        };
      };
      compootuers.path = ./compootuers;
      imports = with inputs; [
        nix-genesis.compootuers
        nix-genesis.fmt
      ];
    };
  inputs = {
    nix = {
      type = "github";
      owner = "NixOS";
      repo = "nix";
    };
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

### WTF is inputs.nix-genesis.mkFlake ?
It is an alias to `inputs.nix-genesis.inputs.flake-parts.lib.mkFlake`, it is to avoid having to type that all out or alternativly adding  flake-parts to your flake inputs  and typing out `inputs.flake-parts.lib.mkFlake`, flake bullshit 😁, or my bullshit 😁.


### Using the Library Module

You can use the `lib.nix` utilities in your NixOS configurations by adding:

```nix
imports = [ "${inputs.nix-genesis.outPath}/lib.nix" ];
```

This allows you to leverage helper functions from `nix-genesis` in your configurations.

---

## Formatting & Linting

You can enable built-in formatting tools via **treefmt** without explicitly adding treefmt-nix to your flake inputs and then adding their module by including `inputs.nix-genesis.fmt` in your imports (done via alias as well 🥲. Many formatter are available, here are a few you will likely want to use:

- `nixfmt` (for formatting Nix code)
- `deadnix` (for removing unused code)
- `statix` (for static analysis)
- `dos2unix` (for normalizing line endings)

You can set up `treefmt` by adding:

```nix
perSystem.treefmt = {
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true;
    deadnix.enable = true;
    statix.enable = true;
    dos2unix.enable = true;
  };
};
```

And run the formatter with:

```bash
nix fmt
```

---

## Host Configuration Directory Hierarchy for compootuers module

To enable per-host configurations, set `config.compootuers.path` to a directory containing host configuration files, structured as follows:

```
/path/to/hosts/            # This directory is set in config.compootuers.path
├── x86_64-linux           # Directory for the x86_64-linux architecture
│   ├── host1              # Host directory for "host1"
│   │   ├── both.nix       # (Optional) Configuration applied to both ISO and non-ISO builds
│   │   ├── default.nix    # (Optional) Configuration for standard (non-ISO) builds
│   │   └── iso.nix        # (Optional) Configuration for ISO builds (e.g., for installation media)
│   └── host2
│       └── both.nix       # This host may only require a common configuration
└── aarch64-linux          # Directory for the aarch64-linux architecture
    ├── host3
    │   ├── default.nix
    │   └── iso.nix
    └── host4
        └── both.nix
```

This setup ensures a structured and scalable approach to managing multiple NixOS configurations.

## TODO:
- ⭕ Add a dwarin module, don't have a mac yet, so unlikely to be done anytime soon!!
- ⭕ Add a module for non linux distro computers
- ⭕ Get rid of flakes, DREAMSSSS 😴💭🤤
