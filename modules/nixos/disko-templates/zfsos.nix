{
  ashift,
  diskName,
  device,
  swapSize,
  ...
}:
let
  esp = import ./esp.nix { inherit diskName; };
in
{
  disko.devices = {
    disk = {
      ${diskName} = {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            inherit esp;
            encryptedSwap = {
              size = "${swapSize}";
              content = {
                type = "swap";
                randomEncryption = true;
                discardPolicy = "both";
                priority = 100;
              };
            };
            zfsos = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "${diskName}-zfsos";
              };
            };
          };
        };
      };
    };
    zpool = {
      "${diskName}-zfsos" = {
        type = "zpool";
        options = {
          autotrim = "off";
          inherit ashift;
        };
        rootFsOptions = {
          compression = "zstd";
          acltype = "posixacl";
          atime = "off";
          xattr = "sa";
          normalization = "formD";
          mountpoint = "none";
          canmount = "off";
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "prompt";
          sync = "disabled";
          dnodesize = "auto";
        };
        datasets = {
          faketmpfs = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "/";
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "/nix";
          };
          tmp = {
            type = "zfs_fs";
            mountpoint = "/tmp";
            options.mountpoint = "/tmp";
          };
          persist = {
            type = "zfs_fs";
            mountpoint = "/persist";
            options.mountpoint = "/persist";
          };
          ${diskName} = {
            type = "zfs_fs";
            mountpoint = "/mnt/${diskName}";
            options.mountpoint = "/mnt/${diskName}";
          };
          reserved = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              reservation = "10G";
            };
          };
        };
        postCreateHook = "zfs snapshot ${diskName}-zfsos/faketmpfs@blank";
      };
    };
  };
}
