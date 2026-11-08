{ config, lib, pkgs, ... }:

{
  # -----------------------------------------------------------------------
  # COSMIC - System76's Wayland-native desktop. It brings its own session,
  # greeter (cosmic-greeter), settings, and xdg-desktop-portal-cosmic (which
  # is what gives OBS/Sunshine/browsers screen capture on this compositor).
  # COSMIC owns its own theming, so there are no desktop dotfiles to ship.
  # -----------------------------------------------------------------------

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # The COSMIC module installs the core desktop/apps; add a browser.
  environment.systemPackages = with pkgs; [
    firefox
  ];

  # Wayland-native toolkits + Ozone for Electron/Chromium apps (Heroic,
  # Bottles UI, Discord/Vesktop, VS Code, ...).
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };
}
