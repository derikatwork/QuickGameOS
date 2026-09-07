{ config, lib, pkgs, ... }:

let
  cfg = config.quickgameos;
  wantLabwc = cfg.desktop == "labwc" || cfg.desktop == "both";
in
{
  # -----------------------------------------------------------------------
  # labwc - a lightweight, Openbox-inspired Wayland compositor. This is the
  # spiritual successor to the BunsenLabs/Openbox experience: a stacking
  # (not tiling) compositor driven by a right-click root menu, a thin panel,
  # keyboard shortcuts and a dark theme. Per-user config (rc.xml, menu,
  # autostart, panel) is deployed by home-manager in home/gamer.nix.
  # -----------------------------------------------------------------------
  config = lib.mkIf wantLabwc (
    let
      # Register labwc as a proper login session so it shows up at the SDDM
      # greeter (and is a valid defaultSession). The override guarantees
      # providedSessions is set regardless of the nixpkgs revision.
      labwcSession = pkgs.labwc.overrideAttrs (old: {
        passthru = (old.passthru or { }) // { providedSessions = [ "labwc" ]; };
      });
    in
    {
    services.displayManager.sessionPackages = [ labwcSession ];

    environment.systemPackages = with pkgs; [
      labwcSession

      # Panel / bar
      waybar

      # Wallpaper, notifications, launcher, screen lock, idle
      swaybg
      mako
      wofi
      fuzzel
      swaylock-effects
      swayidle

      # Screenshots / screen capture helpers
      grim
      slurp
      wf-recorder
      swappy

      # Session plumbing
      lxqt.lxqt-policykit          # polkit auth agent
      networkmanagerapplet         # nm-applet tray
      brightnessctl
      wlr-randr
      kanshi                       # display profiles / hotplug

      # Everyday apps so the lightweight desktop is actually usable
      foot                         # fast Wayland terminal
      pcmanfm                      # file manager
      lxappearance                 # GTK theme picker (BunsenLabs staple)
      xfce.xfconf
      firefox
    ];

    # Fonts + cursor visible to GTK apps under labwc.
    programs.dconf.enable = true;
    }
  );
}
