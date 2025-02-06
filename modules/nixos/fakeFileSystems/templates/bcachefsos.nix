{ diskName, device, swapSize, ... }:
let
  esp = import ./esp.nix { inherit diskName; };
in
{
  disko.devices = {
    disk = {
      "${diskName}" = {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            inherit esp;
            swap = {
              size = "${swapSize}";
              content = {
                type = "swap";
                randomEncryption = true;
                discardPolicy = "both";
                priority = 100;
              };
            };
            "nix" = {
              end = "-10GiB";
              content = {
                type = "filesystem";
                format = "bcachefs";
                mountpoint = "/nix";
                extraArgs = [
                  "-f"
                  "--compression=zstd:3"
                  "--background_compression=zstd"
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
