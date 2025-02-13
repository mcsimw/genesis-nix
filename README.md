# nix-genesis

> [!WARNING]
> This is really only made to be used by me, likely it will go through a lot of
> breaking changes so I do not recommend you use it on your own system. If you
> do like it though, consider forking it or using it as inspiration.

**nix-genesis** is essentially a set of nixosModules and [flake-parts](https://github.com/hercules-ci/flake-parts) modules for generating and managing reproducible NixOS configurations across multiple architectures, with a streamlined workflow for creating and maintaining both system and ISO configurations and some other niceties.

---

## Overview

nix-genesis is designed to generate host-specific NixOS configurations with a clear separation of concerns:

- **Host Configuration:** Uses the `flakeModules.compootuers` module to automatically detect and build configurations for multiple hosts based on a prescribed directory structure.
- **System Defaults:** The `nixosModules.sane` module provides a set of carefully selected defaults for networking, hardware, services, programs, and boot options to ensure a stable and predictable system.
- **Nix Configuration:** The `nixosModules.nix-conf` module refines the Nix package manager environment, pinning flake inputs, defining registry behavior, and enabling crucial experimental features.

Together, these modules help you maintain reproducible, secure, and easy-to-customize configurations for your systems.

---

## nixosModules Details

### nixosModules.sane

applies essential configurations that improve reliability and security:

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

### nixosModules.nix-conf

The `nix-conf.nix` module customizes the behavior of the Nix package manager:

- **Flake Inputs Pinning:**

  - Introduces `nix.inputsToPin`, which ensures critical flake inputs like `nixpkgs` remain locked for stability.

- **Nix Settings:**

  - Enforces sandboxing and security settings.
  - Enables experimental features like `nix-command`, `flakes`, and `auto-allocate-uids`.
  - Configures trusted users and caching settings to optimize builds.

---

> [!WARNING]
> You could use these modules standalone but they are meant to integrate with
> the flakeModules.compootuers module. Do not import these modules in any of 
> your configurations inside the compootuers.path, as they are already imported
> by default for all the individual computer configurations in there!!

## Using nix-genesis in Your Configuration

```nix
{
  description = "yay";
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      compootuers.path = ./compootuers;
      imports = with inputs; [
        nix-genesis.flakeModules.compootuers # This is for now the only flake-parts module available for now
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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts = "flake-parts";
      };
    };
    flake-parts = {
      type = "github";
      owner = "hercules-ci";
      repo = "flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs"; 
    };
  };
}
```
### Using the Library Module

You can use the `lib.nix` utilities in your NixOS configurations by adding:

```nix
imports = [ "${inputs.nix-genesis.outPath}/lib.nix" ];
```

This allows you to leverage helper functions from `nix-genesis` in your configurations.

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
⭕ Add a dwarin module to flakeModules, don't have a mac yet, so unlikely to be done anytime soon!!

⭕ Add a module for non linux distro computers to flakeModules

⭕ Get rid of flakes, DREAMSSSS 😴💭🤤
