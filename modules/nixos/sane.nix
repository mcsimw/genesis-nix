{ config, lib, ... }:
{
  networking = {
    useDHCP = lib.mkDefault true;
    useNetworkd = lib.mkDefault true;
    hostId = lib.mkForce (
      builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName)
    );
  };
  hardware.graphics.enable32Bit = lib.mkDefault true;
  users.mutableUsers = lib.mkDefault false;
  security = {
    polkit.enable = lib.mkForce true;
    rtkit.enable = lib.mkForce config.services.pipewire.enable;
  };
  services = {
    fstrim.enable = lib.mkForce true;
    pulseaudio.enable = lib.mkForce false;
    earlyoom.enable = lib.mkForce true;
    udisks2.enable = lib.mkForce true;
    dbus.implementation = lib.mkForce "broker";
    zfs = lib.mkIf config.boot.zfs.enabled {
      autoScrub = lib.mkForce {
        enable = true;
        interval = "daily";
      };
      trim = lib.mkForce {
        enable = true;
        interval = "daily";
      };
    };
  };
  environment = {
    variables.NIXPKGS_CONFIG = lib.mkForce "";
    defaultPackages = [ ];
  };
  programs = {
    direnv.enable = lib.mkForce true;
    command-not-found.enable = lib.mkForce false;
    vim = {
      enable = lib.mkDefault true;
      defaultEditor = true;
    };
    fuse.userAllowOther = true;
    git = {
      enable = lib.mkForce true;
      lfs.enable = lib.mkDefault true;
    };
  };
  documentation = {
    enable = lib.mkForce true;
    man.enable = lib.mkForce true;
    doc.enable = lib.mkForce false;
    nixos.enable = lib.mkForce false;
    info.enable = lib.mkForce false;
  };
  boot = {
    initrd.systemd.enable = lib.mkDefault true;
    /*
      The `zfs.forceImportRoot` option is set to false by default (using `lib.mkForce false`).
      This default setting may cause NixOS to fail to boot if it cannot automatically import the
      root ZFS pool. In such situations, you need to force the import by providing the kernel parameter
      `zfs_force=1` (for example, by manually editing the kernel parameters in your bootloader).

      This workaround is generally only required for the first boot after installation. Once the
      system has successfully imported the pool and is running, the issue should not recur—provided
      that critical factors (such as a consistent `hostId`) remain unchanged.

      Keep in mind that this setting only offers a security benefit if you also prevent modifications to
      kernel parameters at boot time. If such modifications are allowed, a user could simply add
      `zfs_force=1`, negating the intended safeguard.

      Furthermore, if you are using NixCastratum, the `hostId` is automatically derived from your hostname,
      ensuring consistency between the installation ISO and the installed system, which in turn minimizes
      the likelihood of encountering this boot issue.
   */
    zfs.forceImportRoot = lib.mkForce false;
  };
}
