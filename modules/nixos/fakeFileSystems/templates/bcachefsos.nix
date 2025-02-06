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
