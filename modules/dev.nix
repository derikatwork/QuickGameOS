{ config, lib, pkgs, ... }:

let
  cfg = config.quickgameos;
in
{
  # -----------------------------------------------------------------------
  # Dev category - a general software-development bundle: editor, common
  # toolchains, and rootless containers. Off by default.
  # -----------------------------------------------------------------------
  config = lib.mkIf cfg.dev.enable {
    # Rootless containers via Podman with a Docker-compatible CLI/socket.
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;        # provides a `docker` alias
      defaultNetwork.settings.dns_enabled = true;
    };

    # direnv integration for per-project dev shells.
    programs.direnv.enable = true;

    environment.systemPackages = with pkgs; [
      # Editors
      vscode
      neovim

      # Toolchains / languages
      gcc
      gnumake
      cmake
      pkg-config
      python3
      nodejs
      go
      rustup

      # Container / VCS helpers
      podman-compose
      gh
      lazygit
      jq
      yq-go
      httpie
    ];
  };
}
