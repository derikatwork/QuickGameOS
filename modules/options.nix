{ lib, ... }:

with lib;

{
  # -----------------------------------------------------------------------
  # QuickGameOS knobs. Everything user-facing about the distro is toggled
  # from the `quickgameos.*` namespace so a host only has to say what it
  # wants, not how it works.
  # -----------------------------------------------------------------------
  options.quickgameos = {
    username = mkOption {
      type = types.str;
      default = "gamer";
      description = "Primary interactive user created by QuickGameOS.";
    };

    fullName = mkOption {
      type = types.str;
      default = "QuickGameOS Player";
      description = "Display / GECOS name for the primary user.";
    };

    desktop = mkOption {
      type = types.enum [ "labwc" "plasma" "both" ];
      default = "both";
      description = ''
        Which Wayland desktop(s) to install.

        - "labwc"  : the lightweight, BunsenLabs/Openbox-style compositor.
        - "plasma" : KDE Plasma 6, the heavier full-featured desktop with
                     the best VRR/HDR/per-game story.
        - "both"   : install both and pick one at the login screen
                     (recommended - this is the default).
      '';
    };

    gaming.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install and configure the gaming stack (Steam, Lutris, Heroic, Bottles, gamescope, gamemode, MangoHud, ...).";
    };

    streaming.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install and configure the streaming stack (OBS Studio + plugins, virtual camera, Sunshine host).";
    };

    extras = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Master switch for the QuickGameOS extras (emulation, communication, peripherals, media). Turn individual categories off below.";
      };

      emulation = mkOption {
        type = types.bool;
        default = true;
        description = "RetroArch + standalone emulators and an ES-DE frontend (an EmuDeck-style retro setup).";
      };

      communication = mkOption {
        type = types.bool;
        default = true;
        description = "Chat/voice apps that streamers live in (Vesktop - a Wayland-friendly Discord).";
      };

      peripherals = mkOption {
        type = types.bool;
        default = true;
        description = "Gaming peripheral tools: OpenRGB lighting, gaming-mouse config (Piper), Logitech (Solaar), controller remapping, and a Moonlight client.";
      };

      media = mkOption {
        type = types.bool;
        default = true;
        description = "Media apps handy on a gaming/streaming box (mpv, Spotify).";
      };
    };

    autoUpdate = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable weekly automatic system updates.";
      };

      flake = mkOption {
        type = types.str;
        default = "github:derikatwork/quickgameos#quickgameos";
        description = ''
          The flake reference the weekly auto-update rebuilds from. Point
          this at your own fork/branch (or a local path like
          "/etc/nixos#quickgameos") so the machine tracks a config you
          control. Whatever you point at must contain this host's
          hardware-configuration.nix.
        '';
      };

      allowReboot = mkOption {
        type = types.bool;
        default = false;
        description = "Let the weekly update reboot the machine when the kernel/initrd changed. Off by default so it never yanks you out of a game.";
      };
    };
  };
}
