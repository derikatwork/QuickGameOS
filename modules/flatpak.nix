{ config, lib, pkgs, ... }:

{
  # -----------------------------------------------------------------------
  # Flatpak + Flathub - the Fedora-style way to install apps alongside the
  # native nixpkgs stack. Steam, Lutris, Heroic, Bottles, OBS and more are
  # all available as Flatpaks from Flathub if you prefer them to the native
  # builds (handy for sandboxing or newer upstream releases).
  #
  # On NixOS this is the analog of "Fedora + RPM Fusion + Flatpak": native
  # packages for the base stack, allowUnfree + full codecs for the RPM-Fusion
  # bits (set in base.nix / amd.nix), and Flathub for everything else.
  # -----------------------------------------------------------------------

  services.flatpak.enable = true;

  # Register Flathub on first boot so `flatpak install flathub <app>` and the
  # COSMIC Store just work. Idempotent.
  systemd.services.flathub-remote = {
    description = "Add the Flathub Flatpak remote";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      flatpak remote-add --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
  };
}
