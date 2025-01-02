{ config, lib, ... }:
{
  networking = lib.mkDefault {
    useDHCP = true;
    useNetworkd = true;
  };
  hardware = {
    graphics.enable32Bit = lib.mkDefault true;
    enableAllFirmware = lib.mkDefault true;
    pulseaudio.enable = lib.mkForce false;
  };
  users.mutableUsers = lib.mkDefault false;
  security = {
    polkit.enable = lib.mkDefault true;
    rtkit.enable = config.services.pipewire.enable;
  };
  services = {
    fstrim.enable = lib.mkDefault true;
    earlyoom.enable = lib.mkDefault true;
    udisks2.enable = lib.mkDefault true;
    dbus.implementation = lib.mkDefault "broker";
    zfs = lib.mkIf config.boot.zfs.enabled {
      autoScrub = lib.mkDefault {
        enable = true;
        interval = "daily";
      };
      trim = lib.mkDefault {
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
    command-not-found.enable = lib.mkDefault false;
    vim = {
      enable = lib.mkDefault true;
      defaultEditor = true;
    };
    fuse.userAllowOther = true;
    dconf.enable = config.hardware.graphics.enable;
    git = {
      enable = lib.mkForce true;
      lfs.enable = true;
    };
  };
  documentation = {
    enable = lib.mkDefault true;
    man.enable = lib.mkDefault true;
    doc.enable = lib.mkForce false;
    nixos.enable = lib.mkForce false;
    info.enable = lib.mkForce false;
  };
  boot = {
    initrd.systemd.enable = lib.mkDefault true;
    zfs.forceImportRoot = lib.mkForce false;
  };
}
