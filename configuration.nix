{ config, pkgs, lib, ... }:

let
  user = "admin";
  # Password to login and manage the Raspberry Pi. Default password: "testing".
  # Generate a password hash using ` mkpasswd -m sha-512 <your secure password>`.
  hashedPassword = "$6$OMJuNPuGfIXsY28y$NhNhm3PtDmJx80NcESlZAn4IH71BEkmqvaeRGWt7WL3UgmursqN.WJsgAHmTc5lC6NOv4kZQeapdnyeZLXgmz.";
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
    firewall = {
      enable = true;
      allowedTCPPorts = [ 2283 ];
      # required for Tailscale
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  environment.systemPackages = with pkgs; [ 
    git
    cryptsetup
    rustic
    vim # basic file editing
    bat # cat with wings
    htop # interactive process viewer
    bottom # graphical system monitoring dashboard for the terminal
    immich-server # Helper script to run immich
    immich-backup # Helper script to backup immich data
  ];

  environment.variables = {
    # Set to "true" to only backup essential data.
    IMMICH_BACKUP_ESSENTIAL_ONLY = "false";
  };

  services.openssh.enable = true;
  services.tailscale.enable = true;

  # More settings can be found here: https://wiki.nixos.org/wiki/Immich
  services.immich = {
    enable = true;
    # use `host = "::";` for IPv6.
    host = "0.0.0.0";
    port = 2283;
    mediaLocation = "/mnt/immich_drive/immich_data";
    secretsFile = "/mnt/immich_drive/secrets/immich-secrets";
  };

  # Set the database location to the encrypted drive
  services.postgresql = {
    dataDir = "/mnt/immich_drive/postgres";
  };

  users.users.immich = {
    # Add immich user to users group, allowing immich to write to our external drive.
    extraGroups = [ "users" ];
  };

  # We do not want immich and postgres to start on boot since we need to first decrypt the drive.
  # You can remove these lines if your immich drive does not require manual decryption.
  systemd.services.postgresql.wantedBy = lib.mkForce [];
  systemd.targets.postgresql.wantedBy = lib.mkForce [];
  systemd.services.immich-server.wantedBy = lib.mkForce [];
  systemd.services.immich-machine-learning.wantedBy = lib.mkForce [];

  systemd.timers."immich-backup" = {
    wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "60m";
        OnUnitActiveSec = "1d";
        Unit = "immich-backup.service";
      };
  };

  systemd.services."immich-backup" = {
    path = [ pkgs.rustic ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${immich-backup}/bin/immich-backup";
    };
    description = "Immich backup service";
  };

  users = {
    mutableUsers = false;
    users."${user}" = {
      isNormalUser = true;
      hashedPassword = hashedPassword;
      extraGroups = [ "wheel" ];
    };
  };

  # Disable bluetooth
  hardware.bluetooth = {
    enable = false;
    powerOnBoot = false;
  };

  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
}