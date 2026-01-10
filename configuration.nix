{ config, pkgs, lib, ... }:

let
  user = "admin";
  # The initial password to login and manage the Raspberry Pi.
  # Change this with `sudo passwd <user>` once logged it.
  # Subsequent `nixos-rebuild switch` will not change the password back to "testing".
  initialPassword = "testing";
  hostname = "immich";
  immich-server = pkgs.writeShellScriptBin "immich-server" (builtins.readFile ./scripts/immich-server.sh);
  immich-backup = pkgs.writeShellScriptBin "immich-backup" (builtins.readFile ./scripts/immich-backup.sh);
in {

  imports = [
    ./zsh.nix
    # ./lan-immich.nix
    ./expose-immich.nix
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
    firewall.enable = true;
  };

  environment.systemPackages = with pkgs; [ 
    git
    cryptsetup
    rustic
    vim # basic file editing
    tmux # terminal multiplexer
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

  services.openssh = {
    enable = true;
    # Uncomment these `settings` lines to require public key authentication only.
    # Read [Harden RPi with SSH keys](https://hicklin.github.io/immich-rpi-nix/optional-extras/1-harden-rpi-with-ssh-keys.html)
    # Disables remote password authentication.
    # settings.PasswordAuthentication = false;
    # Disables keyboard-interactive authentication.
    # settings.KbdInteractiveAuthentication = false;
  };

  services.tailscale.enable = true;

  # More settings can be found here: https://wiki.nixos.org/wiki/Immich
  services.immich = {
    enable = true;
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

  # Creates the immich backup timer
  systemd.timers."immich-backup" = {
    wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "60m";
        OnUnitActiveSec = "1d";
        Unit = "immich-backup.service";
      };
  };

  # Creates the immich backup service
  systemd.services."immich-backup" = {
    path = [ pkgs.rustic ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${immich-backup}/bin/immich-backup";
      TimeoutStopSec = 60;
    };
    description = "Immich backup service";
  };

  # Configures the avahi daemon enabling mDNS lookup of the RPi with `immich.local`.
  services.avahi = {
    enable = true;
    hostName = hostname;
    publish = {
      enable = true;
      userServices = true;
      addresses = true;
    };
    nssmdns4 = true; # Enables mDNS resolution for .local domains
    openFirewall = true; # Opens UDP port 5353 for mDNS
  };

  users = {
    mutableUsers = true;
    users."${user}" = {
      isNormalUser = true;
      initialPassword = initialPassword;
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