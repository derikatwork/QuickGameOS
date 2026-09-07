{ config, lib, pkgs, ... }:

let
  cfg = config.quickgameos;
in
{
  # -----------------------------------------------------------------------
  # The primary interactive user + its home-manager theming. Imported by the
  # installed host (the live ISO wires home-manager to its own "nixos" user
  # instead, so this module stays out of the ISO to avoid clashing).
  # -----------------------------------------------------------------------

  users.users.${cfg.username} = {
    isNormalUser = true;
    description = cfg.fullName;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"           # sudo
      "networkmanager"
      "video"
      "audio"
      "input"
    ];
    # Default password is "gamer" - CHANGE IT on first login with `passwd`.
    initialPassword = lib.mkDefault "gamer";
  };

  home-manager.users.${cfg.username} = import ../home/gamer.nix;
}
