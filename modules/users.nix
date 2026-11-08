{ config, lib, pkgs, ... }:

let
  cfg = config.quickgameos;
in
{
  # -----------------------------------------------------------------------
  # The primary interactive user. Imported by the installed host (the live
  # ISO uses its own "nixos" user, so this module stays out of the ISO).
  # COSMIC owns per-user desktop config, so there's no home-manager here.
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
}
