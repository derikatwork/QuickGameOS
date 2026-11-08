{
  description = "QuickGameOS - a Nix-powered, gaming-first NixOS config with the COSMIC desktop, tracking Fedora-level freshness (latest stable kernel + current software), Steam/Lutris/Heroic/Bottles + Flatpak, OBS + Sunshine, weekly auto-updates";

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
    in
    {
      # ---------------------------------------------------------------------
      # The QuickGameOS system. Apply to a minimal NixOS install (or any
      # existing NixOS) with:
      #   sudo nixos-rebuild switch --flake .#quickgameos
      # Replace hosts/quickgameos/hardware-configuration.nix with the output
      # of `nixos-generate-config` for your machine first. See the README's
      # "From minimal NixOS to full QuickGameOS" guide.
      # ---------------------------------------------------------------------
      nixosConfigurations.quickgameos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./modules/options.nix
          ./modules/base.nix
          ./modules/amd.nix
          ./modules/audio.nix
          ./modules/gaming.nix
          ./modules/flatpak.nix
          ./modules/streaming.nix
          ./modules/extras.nix
          ./modules/desktop
          ./modules/auto-update.nix
          ./hosts/quickgameos
        ];
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    };
}
