# Introduction

This project aims to provide a cheap and simple way to set up and run an [Immich](https://immich.app/) instance, empowering you to move away from BigTech without needing a computer degree. Having said that, you will be running your own server which will require an understanding of some basic concepts. This project attempts to provide sufficient documentation and explanations to help you on your way to regain sovereignty over your personal data.

The primary setup described aims to protect against the following treats.
- Third-party companies accessing personal media assets.
- Remote internet access of server and data. Requires small overhead [maintaining OS updates](./management/3-maintenance.md#os-updates).
- Access from local network. Requires setting strong passwords.
- Physical access to external storage and RPi SD card. Requires [encryption of external drive](./setup/1-encrypt-drive.md).

There are alternative setup procedures to the main setup that address different requirements. References to these deviations will be made in the main setup procedure. Hence, you are encourage to follow the main setup procedure for all alternatives.

> [!CAUTION]
> You will be taking back control of your media assets. You will be solely responsible for keeping them safe and accessible. This process requires a number of credentials to be created, without which no one, including yourself, can get access to this data.
> 
> Ensure that these credentials are stored securely. All instances where important credentials are created contain a similar caution note. Below is a summary of all the necessary passwords. You are encouraged to generate and store them in your password manager before proceeding.
> | Password                 | Step  | notes     |
> |--------------------------|-------|-----------|
> | External disk encryption | 1     |           |
> | RPi login                | 2.6.3 |           |
> | Immich database          | 3.1.6 | A-Za-z0-9 |
> | Immich admin user        | 3.4   |           |
> | Backup data encryption   | 4.2   |           |

> [!NOTE]
> The following instruction have been devised and tested on a Linux based OS. Instructions for other OSs may be incomplete. If you want to follow along on a Linux based OS, you can run one from a live USB without installing it on your machine.
