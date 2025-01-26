{ config, lib, ... }:
{
  networking = lib.mkDefault {
    useDHCP = true;
    useNetworkd = true;
  };
  hardware.graphics.enable32Bit = lib.mkDefault true;
  users.mutableUsers = lib.mkDefault false;
  security = {
    polkit.enable = lib.mkDefault true;
    rtkit.enable = config.services.pipewire.enable;
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
    direnv.enable = true;
    command-not-found.enable = lib.mkForce false;
    vim = {
      enable = lib.mkDefault true;
      defaultEditor = true;
    };
    fuse.userAllowOther = true;
    dconf.enable = lib.mkForce config.hardware.graphics.enable;
    git = {
      enable = lib.mkForce true;
      lfs.enable = true;
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
    initrd.systemd.enable = lib.mkForce true;
    zfs.forceImportRoot = lib.mkForce false;
  };
}
