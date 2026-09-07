{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  # -----------------------------------------------------------------------
  # A live + installer QuickGameOS image, kept deliberately LEAN so it can
  # be built on a normal CI runner and downloaded.
  #
  # It boots a themed labwc live session with the NixOS installer tooling
  # and the full QuickGameOS flake embedded on disk. You install the FULL
  # experience (Steam, Plasma, emulators, streaming, ...) to your drive from
  # that embedded flake - so the heavy stack lives on the installed system,
  # not on the image you download.
  #
  #   Build:  nix build .#iso
  #   Image:  ./result/iso/quickgameos-*.iso
  # -----------------------------------------------------------------------
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-base.nix")
  ];

  # Lean live image: just the lightweight desktop + installer. The gaming,
  # streaming and extras stacks are NOT baked into the ISO (they'd make it
  # huge); they install onto the target system from the embedded flake.
  quickgameos = {
    desktop = "labwc";
    gaming.enable = false;
    streaming.enable = false;
    extras.enable = false;
    autoUpdate.enable = false;
  };

  # The live user gets the QuickGameOS theme so the image still looks the part.
  home-manager.users.nixos = import ../home/gamer.nix;
  users.users.nixos.extraGroups = [ "video" "audio" "input" "networkmanager" ];

  # Auto-login into the live desktop (the live account has no password, which
  # a graphical greeter would otherwise reject).
  services.displayManager.autoLogin = {
    enable = true;
    user = "nixos";
  };

  # Embed the whole QuickGameOS flake on the image so installation is fully
  # offline - no git clone needed. `inputs.self` is this flake's clean source.
  environment.etc."quickgameos".source = inputs.self;

  # Image identity + a faster-to-produce squashfs.
  isoImage.squashfsCompression = "zstd -Xcompression-level 9";
  isoImage.isoName = lib.mkForce "quickgameos-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage.volumeID = lib.mkForce "QUICKGAMEOS";
  isoImage.appendToMenuLabel = " QuickGameOS Live";

  # Broadly-compatible kernel for booting on varied hardware.
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  networking.hostName = lib.mkForce "quickgameos-live";

  # A desktop shortcut + docs pointing at the installer.
  environment.systemPackages = [ pkgs.gparted ];

  environment.etc."quickgameos-install/INSTALL.txt".text = ''
    ============================================================
      Install QuickGameOS
    ============================================================

    The full QuickGameOS flake is already on this image at
    /etc/quickgameos (Steam, Plasma, emulators, streaming, etc. all
    install to your disk from it).

    1. Partition & format your disk (use `sudo gparted`, or the NixOS
       manual). Typical UEFI layout: a 512M-1G EFI System Partition
       (FAT32) + a root partition (ext4).

    2. Mount them:
         sudo mount /dev/<root>  /mnt
         sudo mkdir -p /mnt/boot
         sudo mount /dev/<esp>   /mnt/boot

    3. Copy the flake somewhere writable and add THIS machine's hardware
       config:
         sudo cp -r /etc/quickgameos /mnt/etc/nixos
         sudo nixos-generate-config --root /mnt --show-hardware-config \
           | sudo tee /mnt/etc/nixos/hosts/quickgameos/hardware-configuration.nix

    4. Install:
         sudo nixos-install --flake /mnt/etc/nixos#quickgameos

    5. Reboot, remove the USB, log in as "gamer" / "gamer", then run
       `passwd` to set your own password.

    Game first.
  '';
}
