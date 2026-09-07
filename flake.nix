{
  description = "QuickGameOS - a Nix-powered, BunsenLabs-inspired, gaming-first Wayland OS (Steam, Lutris, Heroic, Bottles, OBS + Sunshine, weekly auto-updates)";

  inputs = {
    # Gaming benefits from a fresh package set, so we track unstable by default.
    # To run the more conservative stable channel instead, change this to
    # "github:NixOS/nixpkgs/nixos-25.05" and point home-manager at its
    # matching "release-25.05" branch below.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      # Modules shared by both the installable system and the live ISO.
      commonModules = [
        ./modules/options.nix
        ./modules/base.nix
        ./modules/amd.nix
        ./modules/audio.nix
        ./modules/gaming.nix
        ./modules/streaming.nix
        ./modules/desktop
        ./modules/theme.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    in
    {
      # ---------------------------------------------------------------------
      # The installed system. Build/apply with:
      #   sudo nixos-rebuild switch --flake .#quickgameos
      # Remember to replace hosts/quickgameos/hardware-configuration.nix with
      # the output of `nixos-generate-config` for YOUR machine first.
      # ---------------------------------------------------------------------
      nixosConfigurations.quickgameos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = commonModules ++ [
          ./modules/auto-update.nix
          ./hosts/quickgameos
        ];
      };

      # ---------------------------------------------------------------------
      # A live, bootable ISO you can try before installing. Build with:
      #   nix build .#iso
      # The image lands in ./result/iso/*.iso
      # ---------------------------------------------------------------------
      nixosConfigurations.iso = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = commonModules ++ [ ./iso ];
      };

      # Convenience alias so `nix build .#iso` works.
      packages.${system}.iso =
        self.nixosConfigurations.iso.config.system.build.isoImage;

      packages.${system}.default = self.packages.${system}.iso;

      # `nix fmt`
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    };
}
