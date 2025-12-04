{ config, pkgs, lib, ... }:

let
  user = "admin";
  password = "testing";
  hostname = "immich";
  immich-server = pkgs.writeShellScriptBin "immich-server" (builtins.readFile ./scripts/immich-server.sh);
  immich-backup = pkgs.writeShellScriptBin "immich-backup" (builtins.readFile ./scripts/immich-backup.sh);
in {

  imports = [
    ./zsh.nix
  ];

  boot = {
    # This linux_rpi4 kernel dose not work for UART. See issue https://github.com/NixOS/nixpkgs/issues/465278
    # Switching to vanilla kernel.
    # kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    kernelPackages = pkgs.linuxPackages;
    kernelParams = lib.mkForce [
        "console=ttyS1,115200n8"
        "console=ttyAMA0,115200n8"
        "console=tty0"
        "nohibernate"
        "loglevel=7"
        "lsm=landlock,yama,bpf"
    ];
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  # Needed for the SD card image build.
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/etc/nixos/configuration.nix"
  ];
  
  nix.settings.experimental-features = [ "nix-command" ];

  networking = {
    hostName = hostname;
  };

  environment.systemPackages = with pkgs; [ 
    git
    vim # basic file editing
    bat # cat with wings
    htop # interactive process viewer
    bottom # graphical system monitoring dashboard for the terminal
    immich-server # Helper script to run immich
    immich-backup # Helper script to backup immich data
  ];

  services.openssh.enable = true;

  users = {
    mutableUsers = false;
    users."${user}" = {
      isNormalUser = true;
      password = password;
      extraGroups = [ "wheel" ];
    };
  };

  # Disable bluetooth
  hardware.bluetooth = {
    enable = false;
    powerOnBoot = false;
  };

  # Size reduction, necessary for keeping release image small
  documentation.enable = false;
  documentation.nixos.enable = false;
  documentation.man.enable = false;
  documentation.info.enable = false;
  documentation.doc.enable = false;

  services.samba.enable = false;

  sdImage = {
    compressImage = true;
    expandOnBoot = true;
  };

  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
}