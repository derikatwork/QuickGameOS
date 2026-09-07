{ config, lib, pkgs, ... }:

{
  # -----------------------------------------------------------------------
  # Base system: Nix itself, unfree packages, garbage collection, shell,
  # fonts and the handful of tools every install wants. Nothing here is
  # host-specific (no bootloader, no filesystems, no users) so this module
  # is safe to import from both the installed system and the live ISO.
  # -----------------------------------------------------------------------

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    # Valve/gaming binary caches so Proton, gamescope, etc. come prebuilt.
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Keep the store tidy - weekly GC pairs nicely with the weekly upgrade.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Target platform (set once here so every host + the ISO agree on it).
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Games and drivers are unfree; allow them.
  nixpkgs.config.allowUnfree = true;

  # Several Electron apps we ship (Heroic, Vesktop, ...) can ride an Electron
  # point-release that upstream has marked EOL/insecure. Allow the Electron
  # runtime specifically, by name, so a routine version bump doesn't wedge the
  # weekly rebuild.
  nixpkgs.config.allowInsecurePredicate =
    pkg: builtins.elem (lib.getName pkg) [ "electron" ];

  # Sensible, gaming-friendly defaults.
  time.timeZone = lib.mkDefault "America/New_York";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  console.keyMap = lib.mkDefault "us";

  # Networking - NetworkManager is the friendliest for a desktop/gaming box.
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # Bluetooth (controllers, headsets).
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # zram helps a lot when a game eats all your RAM.
  zramSwap.enable = true;

  # Fonts - a good spread plus a Nerd Font for the panel/terminal glyphs.
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
    ];
  };

  # Shell niceties.
  programs.zsh.enable = true;
  programs.fish.enable = true;
  environment.shellAliases = {
    qgos-update = "sudo nixos-rebuild switch --flake ${config.quickgameos.autoUpdate.flake}";
    qgos-upgrade = "sudo nixos-rebuild switch --flake ${config.quickgameos.autoUpdate.flake} --upgrade";
  };

  # Baseline CLI tools everyone ends up wanting.
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    htop
    btop
    fastfetch
    tree
    unzip
    p7zip
    file
    pciutils
    usbutils
    lm_sensors
    nvme-cli
    ripgrep
    fd
    bat
    eza
    vim
    micro
    wl-clipboard
  ];

  # Firmware updates.
  services.fwupd.enable = true;

  # Trim SSDs.
  services.fstrim.enable = true;

  # Let non-root users adjust brightness/power via the desktop.
  security.polkit.enable = true;
  security.rtkit.enable = true;

  system.stateVersion = lib.mkDefault "25.05";
}
