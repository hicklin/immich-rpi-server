# Drive encryption/decryption from command line

If you are running from the Windows Subsystem for Linux (WSL2), there may be some preamble to get things started. You can read more about this [here](https://learn.microsoft.com/en-us/windows/wsl/install).

## Drive encryption

1. Identify the path to your drive, similar to `/dev/sdc`.
   - You can follow the kernel logs with `sudo dmesg -w` when plugging in the drive to identify its path.
2. Use `cryptsetup` to encrypt the drive
   ```
   sudo cryptsetup luksFormat <drive path> --type luks2 --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 5000 --use-random
   ```
3. Plug and decrypt the drive
   ```
   sudo cryptsetup open <drive path> <mount name>
   ```
4. Create the file system
   ```
   sudo mkfs.ext4 /dev/mapper/<mount name>
   ```

> [!CAUTION]
> Securely store the encryption password. If you loose it you will loose access to all the files stored in this drive.

#### Decrypting the drive

1. Plug in the drive and identify it's path, similar to above.
2. Decrypt the drive
   ```
   sudo cryptsetup open <drive path> immich_drive
   ```
3. Mount the drive
   ```
   sudo mount /dev/mapper/immich_drive /mnt/immich_drive
   ```
