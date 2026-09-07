{ config, lib, pkgs, ... }:

let
  cfg = config.quickgameos;
  on = category: cfg.extras.enable && category;
in
{
  # -----------------------------------------------------------------------
  # QuickGameOS extras - the "nice to have" gaming/streaming add-ons layered
  # on top of the core stack. Each category is independently toggleable via
  # quickgameos.extras.* (all default on; flip the master switch or an
  # individual category off in your host config).
  # -----------------------------------------------------------------------
  config = lib.mkMerge [

    # ---- Emulation: an EmuDeck-style retro setup ------------------------
    (lib.mkIf (on cfg.extras.emulation) {
      environment.systemPackages = with pkgs; [
        retroarchFull        # RetroArch with the full set of libretro cores
        es-de                # EmulationStation Desktop Edition - the frontend

        # Standalone emulators for the systems that want them:
        dolphin-emu          # GameCube / Wii
        pcsx2                # PlayStation 2
        rpcs3                # PlayStation 3
        ppsspp               # PSP
        cemu                 # Wii U
        mupen64plus          # Nintendo 64
        melonDS              # Nintendo DS
        mgba                 # Game Boy / GBA
        snes9x               # SNES
        flycast              # Dreamcast
      ];
    })

    # ---- Communication -------------------------------------------------
    (lib.mkIf (on cfg.extras.communication) {
      environment.systemPackages = with pkgs; [
        vesktop              # Discord client that behaves on Wayland (good screenshare/streamer mode)
      ];
    })

    # ---- Peripherals: RGB, mice, controllers, remote play client -------
    (lib.mkIf (on cfg.extras.peripherals) {
      # RGB lighting control (motherboards, RAM, GPUs, peripherals).
      services.hardware.openrgb.enable = true;

      # Gaming-mouse configuration (DPI, buttons, RGB) via libratbag/Piper.
      services.ratbagd.enable = true;

      # Logitech wireless devices + Solaar GUI (installs the needed udev rules).
      hardware.logitech.wireless = {
        enable = true;
        enableGraphical = true;
      };

      environment.systemPackages = with pkgs; [
        piper                # GUI for gaming mice (needs ratbagd, above)
        antimicrox           # map controllers to keyboard/mouse
        moonlight-qt         # be a Moonlight *client* too (stream from another host)
      ];
    })

    # ---- Media ---------------------------------------------------------
    (lib.mkIf (on cfg.extras.media) {
      environment.systemPackages = with pkgs; [
        mpv                  # lightweight, scriptable video player
        spotify              # music while you grind
      ];
    })
  ];
}
