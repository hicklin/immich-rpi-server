# Setup RPi from NixOS image

The recommended approach to setup your RPi for this project is the use the released images as part of this repository. If you are having issue with the release images or want to build your RPi starting from a plain NixOS image, you can follow these instructions.

These steps are simplified from [this](https://nix.dev/tutorials/nixos/installing-nixos-on-a-raspberry-pi)  original source.

1. Download the latest NixOS build for your RPi from [Hydra](https://hydra.nixos.org/job/nixos/trunk-combined/nixos.sd_image.aarch64-linux).
2. Flash on to an SD card using your favourite flashing tool. `rpi-imager`, `balena-etcher` or `dd` will do.
3. Choose one
   - Wire a screen, keyboard and mouse to the RPi OR
   - Wire the FTDI cable
     - Connect the TX/RX wires to GPIOs 14 and 15.
     - Plug the USB to you machine, noticing the port assigned to it. You can used `dmesg -w`.
     - Use `picocom -b 115200 /dev/ttyUSB<X>` to monitor the boot.
4. Place the SD card in your RPi and power it.
5. if using an FTDI cable, wait for a minute or so after `starting kernel...` is printed and continue...
	1. Enable UART
      	1. Power off the RPi and remove the SD card.
		1. Mount the SD card back on you machine.
		2. Open `NIXOS_SD/boot/extlinux/extlinux.conf`
		3. Edit the `APPEND` line by replacing `console=ttyS0,115200n8` with `console=ttyS1,115200n8`.
		4. Save and unmount the SD card.
    2. Place the SD card back in the RPi and supply power.
6. Setup the OS
	1. Plug-in an Ethernet cable.
	2. Install git:
	   ```
	   nix-shell -p git
	   ```
	3. Clone this repository:
	   ```
	   git clone https://github.com/hicklin/immich-rpi-server.git
	   ```
	4. Create a symbolic link (shortcut), for our NixOS configuration:
	   ```
	   sudo ln -s ~/immich-rpi-server/configuration.nix /etc/nixos/configuration.nix
	   ```
	5. Change the password at the top of `configuration.nix`.
	6. Update channels:
	   ```
	   sudo nix-channel --update
	   ```
	7. Install all necessary services and applications:
	   ```
	   sudo nixos-rebuild switch
	   ```
	8. Now you can ssh into the RPi with `ssh immich@<IP>` and the password set in step 4.

> [!CAUTION]
> The password set in step 5 is necessary to manage the RPi. If this is breached, attackers can access all of the raw media assets.
> Set a secure password and for better security, setup [SSH keys and disable password authentication](https://wiki.nixos.org/wiki/SSH_public_key_authentication).
