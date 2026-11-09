{ config, lib, pkgs, ... }:

let
  cfg = config.quickgameos;
in
{
  # -----------------------------------------------------------------------
  # Creative / content-creation category - 2D art, photo, audio and video
  # editing. (Screen recording/streaming lives in the streaming category;
  # 3D lives in the modeling category.) Off by default.
  # -----------------------------------------------------------------------
  config = lib.mkIf cfg.creative.enable {
    environment.systemPackages = with pkgs; [
      # Image / illustration
      gimp                 # raster editing
      krita                # digital painting
      inkscape             # vector illustration
      darktable            # RAW photo workflow

      # Audio / video
      audacity             # audio editing
      kdePackages.kdenlive # non-linear video editor
      handbrake            # video transcoding

      fontforge            # font editing
    ];
  };
}
