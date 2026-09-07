{ config, lib, ... }:

let
  cfg = config.quickgameos;
in
{
  # -----------------------------------------------------------------------
  # Weekly automatic updates. This rebuilds the system from the flake you
  # point it at (quickgameos.autoUpdate.flake), refreshing inputs so you
  # actually pick up new nixpkgs each week.
  #
  # NOTE: this is only wired into the *installed* system, never the ISO.
  # -----------------------------------------------------------------------
  config = lib.mkIf cfg.autoUpdate.enable {
    system.autoUpgrade = {
      enable = true;
      flake = cfg.autoUpdate.flake;
      # --refresh re-fetches the flake ref; --recreate-lock-file bumps
      # nixpkgs (and every other input) to its newest commit each run.
      flags = [
        "--refresh"
        "--recreate-lock-file"
        "--no-write-lock-file"
      ];
      dates = "weekly";
      allowReboot = cfg.autoUpdate.allowReboot;
      # If it does reboot, do it in the small hours.
      rebootWindow = {
        lower = "04:00";
        upper = "06:00";
      };
      # Add a little jitter so every QuickGameOS box doesn't hammer the
      # cache at the same instant.
      randomizedDelaySec = "45min";
      persistent = true;
    };
  };
}
