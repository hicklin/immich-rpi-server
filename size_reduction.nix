{ config, pkgs, lib, ... }:

{
  # Aggressive size reduction, necessary for keeping release image small
  documentation.enable = false;
  documentation.nixos.enable = false;
  documentation.man.enable = false;
  documentation.info.enable = false;
  documentation.doc.enable = false;

  services.samba.enable = false;

  services.immich.machine-learning.enable = false;

  sdImage = {
    compressImage = true;  # Already true, but make sure
    expandOnBoot = true;   # Image starts small, expands on first boot
  };
}


