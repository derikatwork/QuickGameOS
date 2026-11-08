# QuickGameOS settings
# ---------------------
# Host identity + which feature categories are enabled. This file is safe to
# regenerate with ./install.sh, and also fine to edit by hand.
{ ... }:
{
  networking.hostName = "quickgameos";
  time.timeZone = "America/New_York";

  quickgameos = {
    username = "gamer";
    desktop = "cosmic";

    # Feature categories
    gaming.enable = true;      # Steam, Lutris, Heroic, Bottles, gamescope, ...
    streaming.enable = true;   # OBS + Sunshine
    office.enable = false;     # LibreOffice, Thunderbird, PDF, KeePassXC

    extras.enable = true;
    extras.emulation = true;        # RetroArch + emulators
    extras.communication = true;    # Vesktop (Discord)
    extras.peripherals = true;      # OpenRGB, Piper, Solaar, Moonlight client
    extras.media = true;            # mpv, Spotify

    autoUpdate.enable = true;
  };
}
