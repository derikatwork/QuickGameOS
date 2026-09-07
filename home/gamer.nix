{ config, lib, pkgs, ... }:

{
  # -----------------------------------------------------------------------
  # Per-user QuickGameOS environment: the dark BunsenLabs-style theme plus
  # the labwc/waybar/menu dotfiles that give the lightweight desktop its
  # look and feel. Works for the installed "gamer" user and the live ISO's
  # "nixos" user alike.
  # -----------------------------------------------------------------------

  home.stateVersion = "25.05";

  # ---- Theme: dark GTK/Qt, Papirus icons, Bibata cursor ----
  gtk = {
    enable = true;
    theme = { name = "Nordic"; package = pkgs.nordic; };
    iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme; };
    cursorTheme = { name = "Bibata-Modern-Classic"; package = pkgs.bibata-cursors; size = 24; };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  # ---- labwc: the Openbox-style Wayland compositor config ----
  xdg.configFile = {
    "labwc/rc.xml".source = ./dotfiles/labwc/rc.xml;
    "labwc/menu.xml".source = ./dotfiles/labwc/menu.xml;
    "labwc/autostart" = { source = ./dotfiles/labwc/autostart; executable = true; };
    "labwc/environment".source = ./dotfiles/labwc/environment;

    # Panel
    "waybar/config.jsonc".source = ./dotfiles/waybar/config.jsonc;
    "waybar/style.css".source = ./dotfiles/waybar/style.css;

    # Launcher
    "wofi/config".source = ./dotfiles/wofi/config;
    "wofi/style.css".source = ./dotfiles/wofi/style.css;

    # Terminal
    "foot/foot.ini".source = ./dotfiles/foot/foot.ini;

    # Notifications
    "mako/config".source = ./dotfiles/mako/config;

    # In-game overlay defaults
    "MangoHud/MangoHud.conf".source = ./dotfiles/mangohud/MangoHud.conf;
  };

  # The wallpaper referenced by labwc/autostart.
  home.file.".local/share/quickgameos/wallpaper.svg".source = ./dotfiles/wallpaper.svg;

  # A couple of user-scoped conveniences.
  programs.home-manager.enable = true;
}
