{ config, lib, pkgs, ... }:

{
  # -----------------------------------------------------------------------
  # The installed QuickGameOS machine. This is where host-specific things
  # live: bootloader, hostname, the primary user, and (crucially) the
  # generated hardware-configuration.nix.
  #
  # BEFORE YOU BUILD: replace hardware-configuration.nix with the output of
  #   sudo nixos-generate-config --show-hardware-config \
  #       > hosts/quickgameos/hardware-configuration.nix
  # run on the target machine, then commit it. Everything else can stay.
  # -----------------------------------------------------------------------
  imports = [
    ./hardware-configuration.nix
    ../../modules/users.nix
  ];

  networking.hostName = "quickgameos";

  # QuickGameOS defaults - override per-host as you like.
  quickgameos = {
    username = "gamer";
    desktop = "both";        # labwc + Plasma 6, choose at login
    gaming.enable = true;
    streaming.enable = true;
    autoUpdate.enable = true;
  };

  # Bootloader - systemd-boot on UEFI. Switch to GRUB below if you're on a
  # BIOS/legacy machine.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  # A quiet, graphical boot with a dark splash, BunsenLabs-style.
  boot.plymouth.enable = true;
  boot.kernelParams = [ "quiet" "splash" ];
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  # Passwordless sudo for the wheel group is convenient on a personal
  # gaming box; drop this if you'd rather be prompted.
  security.sudo.wheelNeedsPassword = lib.mkDefault false;

  system.stateVersion = "25.05";
}
