{
  config,
  lib,
  pkgs,
  ...
}:
{
  networking = {
    useDHCP = lib.mkDefault true;
    hostId = lib.mkForce (
      builtins.substring 0 8 (builtins.hashString "md5" config.networking.hostName)
    );
  };
  hardware.graphics.enable32Bit = lib.mkDefault true;
  xdg.portal.xdgOpenUsePortal = lib.mkDefault true;
  users.mutableUsers = lib.mkDefault false;
  security.polkit.enable = lib.mkForce true;
  services = {
    userborn.enable = lib.mkDefault true;
    fstrim.enable = lib.mkForce true;
    pulseaudio.enable = lib.mkForce false;
    earlyoom.enable = lib.mkForce true;
    udisks2.enable = lib.mkForce true;
    dbus.implementation = lib.mkForce "broker";
    zfs = lib.mkIf config.boot.zfs.enabled {
      autoScrub = {
        enable = lib.mkDefault true;
        interval = lib.mkDefault "daily";
      };
      trim = {
        enable = lib.mkDefault true;
        interval = lib.mkDefault "daily";
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
  environment.systemPackages = with pkgs; [
    # If I use efi systems, install efibootmgr
    (lib.mkIf (
      config.boot.loader.systemd-boot.enable || (config.boot ? lanzaboote && config.boot.lanzaboote.enable)
    ) efibootmgr)
  ];
}
