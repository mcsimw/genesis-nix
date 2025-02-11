{ self, ...}:
{
  imports = with self.inputs; [
    nixosModules.compootuers
  ];
}
