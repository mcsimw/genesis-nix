{ config, lib, ... }:
{
  security = {
    polkit.enable = lib.mkDefault true;
    rtkit.enable = config.services.pipewire.enable;
  };
  services = {
    fstrim.enable = lib.mkDefault true;
    earlyoom.enable = true;
    udisks2.enable = true;
    dbus.implementation = "broker";
    zfs = lib.mkIf config.boot.zfs.enabled {
      autoScrub = {
        enable = true;
        interval = "daily";
      };
      trim = {
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
    command-not-found.enable = false;
    vim = {
      enable = true;
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
    initrd.systemd.enable = true;
    zfs.forceImportRoot = lib.mkForce false;
  };
}
