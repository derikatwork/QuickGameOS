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

    # If the installer captured a password, use its hash file; otherwise fall
    # back to the default "gamer" password - CHANGE IT on first login (`passwd`).
    hashedPasswordFile = lib.mkIf (cfg.hashedPasswordFile != null) cfg.hashedPasswordFile;
    initialPassword = lib.mkIf (cfg.hashedPasswordFile == null) (lib.mkDefault "gamer");
  };
}
