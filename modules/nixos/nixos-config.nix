{
  programs.command-not-found.enable = false;
  documentation = {
    enable = lib.mkDefault true;
    man.enable = lib.mkDefault true;
    doc.enable = lib.mkForce false;
    nixos.enable = lib.mkForce false;
    info.enable = lib.mkForce false;
  };
}
