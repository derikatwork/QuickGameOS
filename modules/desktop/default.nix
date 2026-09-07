{ config, lib, pkgs, ... }:

let
  cfg = config.quickgameos;
  wantLabwc = cfg.desktop == "labwc" || cfg.desktop == "both";
  wantPlasma = cfg.desktop == "plasma" || cfg.desktop == "both";
in
{
  imports = [
    ./labwc.nix
    ./plasma.nix
  ];

  config = {
    # -------------------------------------------------------------------
    # Login screen. SDDM (on Wayland) is a clean greeter that lists every
    # installed session, so with desktop = "both" you get labwc, Plasma and
    # the Steam/gamescope "big picture" session all pickable at login.
    # -------------------------------------------------------------------
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

    # Preselect a sensible session at the greeter. We use the always-valid
    # desktop session names here (labwc / plasma); the Steam "big picture"
    # gamescope session is still one click away in the session menu.
    services.displayManager.defaultSession = lib.mkDefault (
      if wantLabwc then "labwc" else "plasma"
    );

    # -------------------------------------------------------------------
    # xdg desktop portals - required for screen sharing/capture (OBS,
    # Sunshine, browsers) and file pickers on Wayland.
    # -------------------------------------------------------------------
    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      # Plasma ships its own KDE portal; labwc (wlroots) needs the wlr one.
      extraPortals = lib.optionals wantLabwc [
        pkgs.xdg-desktop-portal-wlr
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    # Dark theme everywhere that honours the freedesktop appearance hint.
    environment.sessionVariables = {
      # Wayland-native toolkits + Ozone for Electron/Chromium apps
      # (Heroic, Bottles UI, Discord, VS Code, ...).
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };
  };
}
