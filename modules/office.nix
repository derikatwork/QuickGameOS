{ config, lib, pkgs, ... }:

let
  cfg = config.quickgameos;
in
{
  # -----------------------------------------------------------------------
  # Office / productivity category - a light desktop-work bundle for when
  # QuickGameOS is also someone's everyday machine. Off by default; the
  # installer turns it on if you pick the "office" category.
  # -----------------------------------------------------------------------
  config = lib.mkIf cfg.office.enable {
    environment.systemPackages = with pkgs; [
      libreoffice-fresh     # documents, spreadsheets, slides
      thunderbird           # email / calendar
      evince                # PDF viewer
      keepassxc             # password manager
      gnome-calculator
    ];
  };
}
