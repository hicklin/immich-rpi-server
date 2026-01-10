# Raspberry Pi setup

This project uses the declarative Linux operating system (OS), NixOS. This allows us to bring the system into the required state from configuration files maintained in this repository without the hassle of manual installations.

> [!NOTE]
> NixOS will not be running on an encrypted drive. This is to allow the possibility of remote bring up if the server reboots. However, all secrets and assets will be stored on the encrypted external drive.

1. Download the latest image from the [releases page](https://github.com/hicklin/immich-rpi-nix/releases).
   - You may choose to [build the RPi image locally](../alternative-setups/2-build-image-locally.md) or
   - Start from the [latest vanilla NixOS image](../alternative-setups/3-install-from-vanilla-image.md).
2. Flash the RPi image on to an SD card using your favourite flashing tool; `rpi-imager`, `balena-etcher` or `dd`:
   ```
   sudo dd if=<path to image>.img of=<path to drive> bs=16M status=progress oflag=dsync
   ```
3. Plug-in an Ethernet cable.
4. Place the SD card in your RPi and power it.
5. Login to the RPi from your machine with `ssh admin@immich.local` and password `testing`. 
   - If you have issues using `immich.local`, identify and use the RPi IP with `sudo arp-scan -l`.
   - The first time you login you will be prompted to configure zsh. You can use option `0`.
   > [!NOTE]
   > Alternatively, you can connect a screen, keyboard and mouse and login to the RPi that way with the user `admin` and password `testing`.
6. Once logged in the RPi
   1. Change the default password:
      ```bash
      sudo passwd admin
      ```
      > [!CAUTION]
      > This password is necessary to manage the RPi. If this is breached, attackers can access all of the raw media assets.
      > Set a secure password and for better security, setup [SSH keys and disable password authentication](../optional-extras/1-harden-rpi-with-ssh-keys.md).
   2. Clone this repository: 
      ```bash
      git clone https://github.com/hicklin/immich-rpi-nix.git
      ```
   3. Create a symbolic link (shortcut), for NixOS configuration:
      ```bash
      sudo ln -s ~/immich-rpi-nix/configuration.nix /etc/nixos/configuration.nix
      ```
   4. Update channels:
      ```bash
      sudo nix-channel --update
      ```
   5. Update the OS:
      ```bash
      sudo nixos-rebuild switch
      ```
