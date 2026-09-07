{
  description = "QuickGameOS - a Nix-powered, BunsenLabs-inspired, gaming-first Wayland OS (Steam, Lutris, Heroic, Bottles, OBS + Sunshine, weekly auto-updates)";

  inputs = {
    # Track the current NixOS stable release for steadier weekly auto-updates.
    # (For the very newest gaming packages instead, switch this to
    # "github:NixOS/nixpkgs/nixos-unstable" and home-manager to its default
    # branch below.)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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
        ./modules/extras.nix
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

      # Convenience so `nix build .#iso` (and `.#default`) works.
      packages.${system} =
        let
          isoImage = self.nixosConfigurations.iso.config.system.build.isoImage;
        in
        {
          iso = isoImage;
          default = isoImage;
        };

      # `nix fmt`
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    };
}
