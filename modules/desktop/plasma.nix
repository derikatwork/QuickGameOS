{ config, lib, pkgs, ... }:

let
  cfg = config.quickgameos;
  wantPlasma = cfg.desktop == "plasma" || cfg.desktop == "both";
in
{
  # -----------------------------------------------------------------------
  # KDE Plasma 6 (Wayland) - the heavier, full-featured option with the best
  # gaming ergonomics on Linux: per-output VRR (adaptive sync), HDR, tearing
  # control, and a mature settings UI. Great when you want a "big" desktop
  # or need HDR for a modern title.
  # -----------------------------------------------------------------------
  config = lib.mkIf wantPlasma {
    services.desktopManager.plasma6.enable = true;

    # Trim a couple of the chattier defaults; keep the useful apps.
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      elisa
      khelpcenter
    ];

    environment.systemPackages = with pkgs.kdePackages; [
      kate            # editor
      filelight       # disk usage
      partitionmanager
      kcalc
      isoimagewriter
    ] ++ (with pkgs; [
      firefox
      wayland-utils
    ]);
  };
}
