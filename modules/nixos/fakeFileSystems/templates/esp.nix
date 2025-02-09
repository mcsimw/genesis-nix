{ diskName }:
{
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
    extraArgs = [
      "-n"
      "${builtins.toUpper (diskName + "-esp")}"
    ];
  };
}
