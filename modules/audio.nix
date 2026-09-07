{ config, lib, pkgs, ... }:

{
  # -----------------------------------------------------------------------
  # PipeWire audio - low latency, per-app routing (essential for streaming),
  # and a drop-in PulseAudio/JACK replacement.
  # -----------------------------------------------------------------------

  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pavucontrol        # volume / device mixer
    pwvucontrol        # native PipeWire mixer
    qpwgraph           # visual patchbay for routing game/mic/desktop audio
    helvum             # simpler PipeWire patchbay
    easyeffects        # mic noise suppression, EQ, compressor for streaming
    playerctl
  ];
}
