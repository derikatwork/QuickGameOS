{ config, lib, pkgs, ... }:

{
  # -----------------------------------------------------------------------
  # The QuickGameOS look - a dark, understated theme in the BunsenLabs
  # tradition. The heavy lifting (GTK/Qt theme, icons, cursor, panel colors)
  # is applied per-user by home-manager; here we just make the theme
  # *packages* available system-wide and give the TTY a matching palette.
  # -----------------------------------------------------------------------

  environment.systemPackages = with pkgs; [
    nordic                 # dark GTK/KDE theme
    papirus-icon-theme     # icon set
    bibata-cursors         # cursor theme
    qogir-theme
  ];

  # A calm dark console palette (Nord-ish) for anyone dropping to a TTY.
  console.colors = [
    "2e3440" "bf616a" "a3be8c" "ebcb8b"
    "81a1c1" "b48ead" "88c0d0" "e5e9f0"
    "4c566a" "bf616a" "a3be8c" "ebcb8b"
    "81a1c1" "b48ead" "8fbcbb" "eceff4"
  ];

  # Qt apps follow the platform theme / dark preference.
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };
}
