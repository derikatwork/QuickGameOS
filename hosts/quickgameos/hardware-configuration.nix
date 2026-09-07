{ config, lib, pkgs, modulesPath, ... }:

# ###########################################################################
# ##  TEMPLATE - DO NOT SHIP AS-IS  #########################################
# ###########################################################################
#
# This is a PLACEHOLDER. It will NOT boot your machine, because the disks,
# filesystem UUIDs and CPU below are almost certainly not yours.
#
# On the target machine (e.g. booted from the QuickGameOS live ISO), run:
#
#     sudo nixos-generate-config --show-hardware-config \
#         > hosts/quickgameos/hardware-configuration.nix
#
# ...then commit the result. That file is what makes the config bootable on
# real hardware. The values below are only here so the flake evaluates and
# so you can see the shape of what's expected.
#
# ###########################################################################

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];   # AMD CPU; use "kvm-intel" on Intel.
  boot.extraModulePackages = [ ];

  # ---- REPLACE THESE with your real UUIDs (blkid) --------------------------
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];
  # -------------------------------------------------------------------------

  networking.useDHCP = lib.mkDefault true;

  # NOTE: `nixos-generate-config` normally emits
  #   nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  # here. QuickGameOS already sets that in modules/base.nix, so it's omitted
  # to avoid a duplicate definition. If you paste in a freshly generated file
  # that includes it, delete the line from base.nix or from here.

  # AMD CPU microcode updates. (For an Intel CPU set the intel option.)
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
