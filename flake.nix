{
  description = "QuickGameOS - a Nix-powered, gaming-first OS with the COSMIC desktop, tracking Fedora-level freshness (latest stable kernel + current software), Steam/Lutris/Heroic/Bottles + Flatpak, OBS + Sunshine, weekly auto-updates";

  inputs = {
    # Track nixos-unstable: it's the NixOS channel closest to Fedora's
    # bleeding-edge freshness, so package and kernel versions line up roughly
    # with a current Fedora release (Fedora 45-era). COSMIC is also best
    # supported here. Pin to a stable release (e.g. nixos-25.11) if you'd
    # rather trade freshness for stability.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";

      # Modules shared by both the installable system and the live ISO.
      commonModules = [
        ./modules/options.nix
        ./modules/base.nix
        ./modules/amd.nix
        ./modules/audio.nix
        ./modules/gaming.nix
        ./modules/flatpak.nix
        ./modules/streaming.nix
        ./modules/extras.nix
        ./modules/desktop
      ];
    in
    {
      # ---------------------------------------------------------------------
      # The installed system:
      #   sudo nixos-rebuild switch --flake .#quickgameos
      # Replace hosts/quickgameos/hardware-configuration.nix with the output
      # of `nixos-generate-config` for your machine first.
      # ---------------------------------------------------------------------
      nixosConfigurations.quickgameos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = commonModules ++ [
          ./modules/auto-update.nix
          ./hosts/quickgameos
        ];
      };

      # ---------------------------------------------------------------------
      # A live, bootable COSMIC installer image:  nix build .#iso
      # The image lands in ./result/iso/*.iso
      # ---------------------------------------------------------------------
      nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = commonModules ++ [ ./iso ];
      };

      packages.${system} =
        let
          isoImage = self.nixosConfigurations.iso.config.system.build.isoImage;
        in
        {
          iso = isoImage;
          default = isoImage;
        };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    };
}
