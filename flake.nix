# Build SD card image with `nix build .#rpi-image`.
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators }: {
    packages.x86_64-linux.rpi-image = nixos-generators.nixosGenerate {
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
      ];
      format = "sd-aarch64";
    };
  };
}