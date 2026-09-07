{ config, lib, pkgs, modulesPath, ... }:

{
  # -----------------------------------------------------------------------
  # A live, bootable QuickGameOS image. It reuses the standard NixOS
  # installation-CD base (which gives us a live "nixos" user, the installer
  # tooling and the ISO build machinery) and layers the full QuickGameOS
  # environment on top, so you can boot it, try labwc/Plasma and the gaming
  # stack, then install to disk.
  #
  #   Build:  nix build .#iso
  #   Image:  ./result/iso/quickgameos-*.iso
  # -----------------------------------------------------------------------
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-base.nix")
  ];

  # Try QuickGameOS with both desktops available at the greeter.
  quickgameos = {
    desktop = "both";
    gaming.enable = true;
    streaming.enable = true;
    # No unattended auto-upgrade on a live image (the module isn't even
    # imported here), but be explicit.
    autoUpdate.enable = false;
  };

  # The live user gets the same themed home as an installed system.
  home-manager.users.nixos = import ../home/gamer.nix;

  # Give the live user the groups the desktop/gaming bits expect.
  users.users.nixos.extraGroups = [ "video" "audio" "input" "networkmanager" ];

  # Auto-login the live user straight into the desktop (the live image's
  # account has no password, which a graphical greeter would reject).
  # Once in, log out to switch between labwc, Plasma and the Steam session.
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  # Sunshine starting itself on a live demo image is surprising; leave it
  # installed but don't autostart it here.
  services.sunshine.autoStart = lib.mkForce false;

  # Faster-to-produce, reasonably sized image.
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";
  isoImage.isoName = lib.mkForce "quickgameos-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage.volumeID = lib.mkForce "QUICKGAMEOS";
  isoImage.appendToMenuLabel = " QuickGameOS Live";

  # Live images can't rely on a hardware-specific kernel; the base already
  # picks a sensible one, so don't force the Zen kernel here.
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

  # A short, friendly hostname for the live session.
  networking.hostName = lib.mkForce "quickgameos-live";

  # Point people at how to actually install.
  environment.etc."quickgameos/INSTALL.txt".text = ''
    Welcome to the QuickGameOS live image!

    To install to disk:
      1. Open a terminal.
      2. Partition/format your disk (see the NixOS manual, or `sudo gparted`).
      3. Mount your target root at /mnt (and ESP at /mnt/boot).
      4. Get the QuickGameOS flake:
           git clone https://github.com/derikatwork/quickgameos /mnt/etc/nixos
      5. Generate hardware config for THIS machine:
           sudo nixos-generate-config --root /mnt --show-hardware-config \
             > /mnt/etc/nixos/hosts/quickgameos/hardware-configuration.nix
      6. Install:
           sudo nixos-install --flake /mnt/etc/nixos#quickgameos
      7. Reboot, log in as "gamer" (password "gamer"), and run `passwd`.

    Have fun. Game first.
  '';
}
