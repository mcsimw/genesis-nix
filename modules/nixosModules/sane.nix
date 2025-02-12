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
      The zfs.forceImportRoot option is set to false by default (lib.mkForce false)
      for security reasons, presumably to enforce ZFS safeguards. However, this may cause
      NixOS to fail to boot because it cannot import the root ZFS pool.

      If the root ZFS pool fails to import, it's likely because it was previously imported
      or initialized by a system with a different hostId. There are two ways to resolve this:

      1. Boot from a NixOS USB installer and override the default setting by adding:
         zfs.forceImportRoot = lib.mkOverride 99999999 true;
         Then, run nixos-install to apply the change. This will allow the system to
         boot and import the pool with your machine’s hostId. Afterward, you can
         choose whether to revert this override.

      2. If permitted by your configuration, add the zfs_force=1 kernel parameter
         to your bootloader. However, if kernel parameters can be modified at boot,
         this may negate the security benefits of keeping this setting disabled.

      Once the pool is successfully imported, NixOS ensures that a persistent hostId
      is set in your nixos configuration whenever ZFS is detected. This ensures stability
      even in ephemeral boot scenarios (e.g., when using a tmpfs root filesystem), minimizing
      the risk of import failures unless intentional reconfiguration occurs.

      If you generated the installation ISO using nix-genesis's compootuers module
      and plan to use it for your actual system, the hostId is automatically derived
      from your hostname, ensuring consistency between the installer and the installed system.
      This significantly reduces the likelihood of encountering this issue. However, for this
      approach to be effective, both the ISO generation and the computer configuration must
      use NixCastratum's compootuers module, as it produces both an ISO output and a matching
      system configuration that are intended to be used together.
    */
    zfs.forceImportRoot = lib.mkForce false;
  };
}
