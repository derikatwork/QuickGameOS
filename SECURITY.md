# Security notes

QuickGameOS is a configuration for a **single-user personal gaming/streaming
desktop**. That's the threat model it's tuned for: a machine with one trusted
operator at the keyboard, not a multi-tenant server. This file records the
security-relevant defaults, the deliberate trade-offs, and how to harden
further.

## Hardening already in place

- **sudo requires a password** (NixOS default). Passwordless sudo is *opt-in*
  (commented in `hosts/quickgameos/default.nix`), because it lets any
  compromised user-level process escalate to root silently.
- **No SSH / remote login by default.** There is no `services.openssh`, so the
  box has no remote shell attack surface out of the box.
- **Firewall on** (`networking.firewall.enable = true`); only the feature
  modules you enable open ports.
- **Installer input validation.** `install.sh` validates the username, hostname,
  timezone and flake-host before writing them into `settings.nix` or the rebuild
  command, so they can't break or inject into the generated Nix.
- **Password handling.** When you set a password in the installer it is read
  hidden, hashed with `mkpasswd`/`openssl`, and written to
  `/etc/quickgameos/password.hash` (mode `0600`, root-only) referenced via
  `hashedPasswordFile` — the plaintext is never stored and the hash is never
  committed. Re-running the installer preserves an existing hash instead of
  reverting to the default password.

## Deliberate trade-offs — review these for your environment

1. **Default password `gamer`.** Used only when you don't set one in the
   installer. **Change it** (`passwd`, or set one during install). Especially
   important if you later enable SSH or any remote access.
2. **Sunshine (game-streaming host)** runs with `capSysAdmin` and
   `openFirewall`, exposing its ports (and the pairing web UI on
   `https://localhost:47990`) to your LAN. Pairing needs a PIN, but if you don't
   stream remotely, disable it: `quickgameos.streaming.enable = false`, or
   firewall Sunshine to a trusted subnet.
3. **Steam** opens remote-play / dedicated-server / local-transfer firewall
   ports. Turn off what you don't use via `programs.steam.*` or
   `quickgameos.gaming.enable = false`.
4. **Insecure Electron allowed by name.** `nixpkgs.config.allowInsecurePredicate`
   permits the Electron runtime regardless of version so an EOL point-release
   (pulled by Heroic/Vesktop/VS Code) doesn't wedge weekly updates. The cost is
   that a known-insecure Electron can ship. Narrow or remove it in
   `modules/base.nix` if you'd rather pin/deny.
5. **Binary caches.** `cache.nixos.org` and `nix-community.cachix.org` are
   trusted substituters (keys pinned in `modules/base.nix`). The second is a
   third-party cache; remove it if you only trust the official one.
6. **Flathub** is added on first boot. Flatpaks are sandboxed but
   community-published — review what you install and its portal permissions.
7. **Weekly auto-updates** (`system.autoUpgrade`) rebuild from
   `quickgameos.autoUpdate.flake`. Point this **only at a repo you control or
   trust** — a compromised upstream would be pulled and built automatically.
   Disable with `quickgameos.autoUpdate.enable = false`.
8. **CoreCtrl / `hardware.amdgpu.overdrive`** exposes the GPU
   overclock/undervolt surface (`amdgpu.ppfeaturemask`). This is a local tuning
   capability, not a network risk.

## Reporting

This is a personal-use template rather than a hosted service. If you spot a bug
or security issue, please open an issue on the repository describing the problem
and the affected file. Do not include real secrets (passwords, tokens) in the
report.
