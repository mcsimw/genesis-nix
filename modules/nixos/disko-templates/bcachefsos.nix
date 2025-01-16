{ diskName, device, ... }:
{
  disko.devices = {
    disk = {
      "${diskName}" = {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            "esp" = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "dmask=0022"
                  "fmask=0022"
                  "umask=0077"
                ];
              };
            };
            "nix" = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "bcachefs";
                mountpoint = "/nix";
                extraArgs = [
                  "-f"
                  "--compression=zstd"
                  "--discard"
                  "--encrypted"
                ];
                mountOptions = [
                  "defaults"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "size=1G"
          "mode=755"
        ];
      };
    };
  };
}
