{ config, lib, pkgs, ... }:

{
  # -----------------------------------------------------------------------
  # AMD Radeon graphics - the smoothest Wayland gaming path. We lean on the
  # in-kernel amdgpu driver + Mesa RADV (the default Vulkan driver), enable
  # 32-bit userspace for Steam/Proton, and add the bits needed for tuning.
  # -----------------------------------------------------------------------

  # Load amdgpu early for a clean, flicker-free boot.
  boot.initrd.kernelModules = [ "amdgpu" ];

  # Track the latest stable mainline kernel, matching how Fedora ships the
  # newest stable kernel (and thus the freshest amdgpu). Swap for
  # pkgs.linuxPackages_zen if you'd prefer the Zen desktop/gaming kernel.
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # Expose the full power/fan/clock control surface so CoreCtrl can tune the
  # GPU (undervolt, fan curves, power profiles). This sets the
  # amdgpu.ppfeaturemask kernel param for us.
  hardware.amdgpu.overdrive.enable = true;

  # Mesa provides RADV (Vulkan) plus VA-API and VDPAU for radeonsi out of
  # the box, and enable32Bit pulls in the 32-bit Mesa userspace Steam/Proton
  # need - so there's nothing extra to add here for a standard Radeon card.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Prefer RADV (Mesa) over AMDVLK explicitly, and route VA-API to the
  # native amdgpu driver for the best OBS/streaming encode.
  environment.variables = {
    AMD_VULKAN_ICD = "RADV";
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
  };

  # CoreCtrl for AMD GPU/CPU tuning from a GUI.
  programs.corectrl.enable = true;

  environment.systemPackages = with pkgs; [
    # Handy AMD/Vulkan diagnostics.
    vulkan-tools
    vulkan-loader
    libva-utils
    radeontop
    nvtopPackages.amd
    clinfo
  ];
}
