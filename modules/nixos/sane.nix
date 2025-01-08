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
    sudo.enable = lib.mkDefault false;
    doas = lib.mkDefault {
      enable = true;
      extraRules = [
        {
          groups = [ "wheel" ];
          keepEnv = true;
          persist = true;
        }
      ];
    };
  };
  services = lib.mkDefault {
    fstrim.enable = true;
    pulseaudio.enable = lib.mkForce false;
    earlyoom.enable = true;
    udisks2.enable = true;
    dbus.implementation = "broker";
    zfs = lib.mkIf config.boot.zfs.enabled {
      autoScrub = {
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
  programs = lib.mkDefault {
    direnv.enable = true;
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
  documentation = lib.mkDefault {
    enable = true;
    man.enable = true;
    doc.enable = lib.mkForce false;
    nixos.enable = lib.mkForce false;
    info.enable = lib.mkForce false;
  };
  boot = lib.mkDefault {
    initrd.systemd.enable = true;
    zfs.forceImportRoot = lib.mkForce false;
  };
}
