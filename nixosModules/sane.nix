{
  lib,
  ...
}:
{
  networking = {
    useDHCP = lib.mkDefault true;
    networkmanager.wifi.powersave = lib.mkDefault false;
  };
  xdg.portal.xdgOpenUsePortal = lib.mkDefault true;
  users.mutableUsers = lib.mkForce false;
  security = {
    polkit.enable = lib.mkDefault true;
    sudo.execWheelOnly = lib.mkForce true;
  };
  services = {
    pulseaudio.enable = lib.mkForce false;
    udisks2.enable = lib.mkDefault true;
    dbus.implementation = lib.mkForce "broker";
    userborn.enable = lib.mkForce true;
  };
  environment = {
    variables.NIXPKGS_CONFIG = lib.mkForce "";
    defaultPackages = [ ];
  };
  programs = {
    direnv = {
      enable = lib.mkDefault true;
      silent = lib.mkDefault true;
    };
    command-not-found.enable = lib.mkForce false;
    fuse.userAllowOther = true;
    git = {
      enable = lib.mkForce true;
      lfs.enable = lib.mkDefault true;
    };
    nano.enable = false;
  };
  documentation = {
    enable = lib.mkForce true;
    man.enable = lib.mkForce true;
    doc.enable = lib.mkForce false;
    nixos.enable = lib.mkForce false;
    info.enable = lib.mkForce false;
  };
}
