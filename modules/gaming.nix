{ config, lib, pkgs, ... }:

let
  cfg = config.quickgameos;
in
{
  config = lib.mkIf cfg.gaming.enable {
    # ---------------------------------------------------------------------
    # Steam - with Proton-GE bundled, remote play + dedicated-server ports
    # opened, and the gamescope micro-compositor session available at login
    # for a console-like "big picture" experience.
    # ---------------------------------------------------------------------
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
      # Ship Proton-GE so newer/unsupported titles work out of the box.
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    # Feral GameMode - CPU governor + IO priority boosts while a game runs.
    programs.gamemode = {
      enable = true;
      settings = {
        general.renice = 10;
        general.inhibit_screensaver = 1;
      };
    };

    # gamescope - Valve's Wayland micro-compositor. capSysNice lets it set
    # RT priority so frame pacing (and FSR upscaling) is smooth.
    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };

    # Controllers: Xbox (xpadneo/xone), PlayStation, 8BitDo, etc.
    hardware.xpadneo.enable = true;
    hardware.xone.enable = true;
    services.joycond.enable = true;

    # Higher esync/proton file-descriptor + memory-map limits so big games
    # (and Easy Anti-Cheat titles) don't hit the ceiling.
    systemd.extraConfig = "DefaultLimitNOFILE=1048576";
    security.pam.loginLimits = [
      { domain = "*"; type = "soft"; item = "nofile"; value = "1048576"; }
      { domain = "*"; type = "hard"; item = "nofile"; value = "1048576"; }
    ];
    boot.kernel.sysctl = {
      # Recommended by Proton/EAC and many modern titles.
      "vm.max_map_count" = 2147483642;
    };

    environment.systemPackages = with pkgs; [
      # --- Launchers ---
      lutris                 # everything-else launcher (GOG, Epic, emulators, ...)
      heroic                 # Epic / GOG / Amazon launcher
      bottles                # run any Windows app/game in tidy prefixes

      # --- Proton / Wine tooling ---
      protonup-qt            # install & manage Proton-GE versions
      protontricks
      winetricks
      wineWowPackages.staging

      # --- Performance overlays & tuning ---
      mangohud               # FPS/frametime/temp overlay
      goverlay               # GUI to configure MangoHud/vkBasalt
      vkbasalt               # post-processing (sharpen, etc.)

      # --- Utilities ---
      gamescope
      gamemode
      steam-run              # run arbitrary dynamic binaries
      steamtinkerlaunch      # per-game tweaks/mods

      # --- A couple of great open-source games so a fresh install isn't empty ---
      superTuxKart
    ];

    # MangoHud config lives in home-manager (home/gamer.nix) so it's tuned
    # per-user; the package above makes the overlay available system-wide.
  };
}
