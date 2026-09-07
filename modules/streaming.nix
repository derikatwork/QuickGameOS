{ config, lib, pkgs, ... }:

let
  cfg = config.quickgameos;

  # OBS Studio wrapped with the plugins a Wayland streamer actually needs.
  obs = pkgs.wrapOBS {
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs                       # wlroots screen capture (labwc)
      obs-pipewire-audio-capture   # per-app audio capture via PipeWire
      obs-vkcapture                # low-overhead Vulkan/OpenGL game capture
      obs-vaapi                    # AMD hardware H.264/HEVC/AV1 encoding
      obs-backgroundremoval        # webcam background removal
      input-overlay                # show keyboard/controller input on stream
      obs-multi-rtmp               # stream to several destinations at once
      advanced-scene-switcher
    ];
  };
in
{
  config = lib.mkIf cfg.streaming.enable {
    # ---------------------------------------------------------------------
    # Content-creation streaming: OBS + virtual camera + capture helpers.
    # ---------------------------------------------------------------------

    # Virtual camera (v4l2loopback) so OBS can output to a webcam device
    # that Discord/Zoom/browsers can consume.
    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];
    boot.extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
    '';

    # obs-vkcapture needs its 32-bit helper for capturing 32-bit games.
    environment.systemPackages = [
      obs
    ] ++ (with pkgs; [
      obs-studio-plugins.obs-vkcapture
    ]);

    # ---------------------------------------------------------------------
    # Game streaming host: Sunshine. Pair it with a Moonlight client on a
    # TV, phone, tablet, Steam Deck or another PC to play remotely.
    # The web UI for pairing lives at https://localhost:47990
    # ---------------------------------------------------------------------
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;   # required for KMS/Wayland screen grab
      openFirewall = true;
    };
  };
}
