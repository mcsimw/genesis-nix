{
  config,
  lib,
  pkgs,
  ...
}:
{
  networking.useDHCP = lib.mkDefault true;
  xdg.portal.xdgOpenUsePortal = lib.mkDefault true;
  users.mutableUsers = lib.mkForce false;
  security = {
    polkit.enable = lib.mkDefault true;
    sudo.execWheelOnly = lib.mkForce true;
  };
  services = {
    userborn.enable = lib.mkDefault true;
    pulseaudio.enable = lib.mkForce false;
    udisks2.enable = lib.mkDefault true;
    dbus.implementation = lib.mkForce "broker";
  };
  environment = {
    variables.NIXPKGS_CONFIG = lib.mkForce "";
    defaultPackages = [ ];
    systemPackages = [
      # If I use efi systems, install efibootmgr
      (lib.mkIf (
        config.boot.loader.systemd-boot.enable
        || (config.boot ? lanzaboote && config.boot.lanzaboote.enable)
      ) pkgs.efibootmgr)
    ];
  };
  programs = {
    direnv.enable = lib.mkDefault true;
    command-not-found.enable = lib.mkForce false;
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
}
