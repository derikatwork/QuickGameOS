# QuickGameOS

**A Nix-powered, BunsenLabs-inspired, gaming-first Wayland OS.**

QuickGameOS is a reproducible NixOS flake that recreates the lean, dark,
right-click-menu spirit of [BunsenLabs](https://www.bunsenlabs.org/) — but on
**Wayland**, powered by **Nix**, and tuned so that **gaming comes first**. Out
of the box you get Steam, Lutris, Heroic and Bottles, a full streaming setup
(OBS + Sunshine), AMD Radeon drivers dialed in for Wayland, and hands-off
weekly auto-updates.

> BunsenLabs is built on Openbox, which is X11-only. Its true Wayland successor
> is **labwc** — an Openbox-style Wayland compositor — so that's the lightweight
> desktop QuickGameOS ships. You can also pick **KDE Plasma 6** at login when you
> want VRR/HDR and a full-featured desktop.

---

## What you get

| Area | Included |
| --- | --- |
| **Desktop** | `labwc` (lightweight, BunsenLabs-style) **and** KDE Plasma 6 — choose at the login screen. Waybar panel, wofi launcher, foot terminal, mako notifications, dark Nordic theme. |
| **GPU** | AMD Radeon on Wayland: amdgpu + Mesa/RADV, 32-bit userspace, Zen kernel, CoreCtrl for tuning, VRR-ready. |
| **Gaming** | Steam (+ Proton-GE, gamescope "big picture" session, GameMode), Lutris, Heroic, Bottles, MangoHud + GOverlay, vkBasalt, ProtonUp-Qt, controller support (Xbox/PS/8BitDo). |
| **Streaming** | OBS Studio with Wayland capture + AMD VAAPI encode + virtual camera; Sunshine host for remote play to Moonlight clients. |
| **Audio** | PipeWire (low-latency, per-app routing), qpwgraph/Helvum patchbays, EasyEffects for mic cleanup. |
| **Maintenance** | Weekly automatic updates + weekly garbage collection. |

---

## Repository layout

```
flake.nix                      # entry point: `quickgameos` system + `iso` image
modules/
  options.nix                  # the quickgameos.* configuration knobs
  base.nix                     # Nix, GC, fonts, networking, CLI tools
  amd.nix                      # AMD Radeon + Wayland graphics
  audio.nix                    # PipeWire
  gaming.nix                   # Steam/Lutris/Heroic/Bottles + tooling
  streaming.nix                # OBS + virtual camera + Sunshine
  auto-update.nix              # weekly system.autoUpgrade
  users.nix                    # the primary user + home-manager wiring
  theme.nix                    # dark theme packages + console palette
  desktop/
    default.nix                # SDDM greeter + xdg portals
    labwc.nix                  # the lightweight compositor
    plasma.nix                 # KDE Plasma 6
hosts/quickgameos/
  default.nix                  # the installed machine (bootloader, hostname)
  hardware-configuration.nix   # TEMPLATE — replace with YOUR hardware
home/
  gamer.nix                    # home-manager theme + dotfiles
  dotfiles/                    # labwc, waybar, wofi, foot, mako, MangoHud, wallpaper
iso/default.nix                # live, bootable image
```

---

## Quick start

### Option A — build a live ISO and try it

```bash
nix build .#iso
# image lands in ./result/iso/quickgameos-*.iso
```

Write it to a USB stick (e.g. with `sudo dd if=result/iso/quickgameos-*.iso
of=/dev/sdX bs=4M status=progress oflag=sync`, or the KDE `isoimagewriter`
included in the image) and boot it. It auto-logs into the desktop; log out to
switch between labwc, Plasma and the Steam session.

### Option B — install to disk from the flake

1. Boot the live ISO (or any NixOS installer) and get the flake:
   ```bash
   git clone https://github.com/derikatwork/quickgameos
   cd quickgameos
   ```
2. Partition/format/mount your target (`/mnt`, ESP at `/mnt/boot`).
3. **Generate this machine's hardware config** (this is required — the checked-in
   one is a non-booting template):
   ```bash
   sudo nixos-generate-config --root /mnt --show-hardware-config \
     > hosts/quickgameos/hardware-configuration.nix
   ```
4. Install:
   ```bash
   sudo nixos-install --flake .#quickgameos
   ```
5. Reboot, log in as **`gamer`** / password **`gamer`**, and immediately run
   `passwd`.

### Option C — apply to an existing NixOS machine

```bash
# after replacing hardware-configuration.nix as in step 3 above:
sudo nixos-rebuild switch --flake .#quickgameos
```

---

## Configuration knobs

Everything user-facing lives under `quickgameos.*` (see `modules/options.nix`).
Set them in `hosts/quickgameos/default.nix`:

```nix
quickgameos = {
  username = "gamer";
  desktop  = "both";        # "labwc" | "plasma" | "both"
  gaming.enable    = true;
  streaming.enable = true;

  autoUpdate = {
    enable = true;
    # Point this at YOUR fork/branch so the weekly rebuild tracks a config
    # you control (it must contain this host's hardware-configuration.nix).
    flake  = "github:derikatwork/quickgameos#quickgameos";
    allowReboot = false;    # true lets kernel updates reboot at 04:00–06:00
  };
};
```

---

## Weekly auto-updates

`modules/auto-update.nix` enables `system.autoUpgrade` on a **weekly** timer. It
runs `nixos-rebuild switch --flake <your flake> --refresh --recreate-lock-file`,
so it pulls the newest nixpkgs each week. A weekly `nix-collect-garbage` keeps
the store trimmed.

Because it rebuilds from a **flake reference**, that flake must contain your
host's `hardware-configuration.nix`. Two common setups:

- **Track your GitHub repo** (default): commit your hardware config and push;
  the machine follows `github:youruser/quickgameos#quickgameos`.
- **Track a local checkout**: set `autoUpdate.flake = "/etc/nixos#quickgameos"`
  and keep the repo in `/etc/nixos`.

Reboots are **off by default** so an update never interrupts a game; set
`autoUpdate.allowReboot = true` to allow kernel updates to reboot in the
early-morning window.

Handy aliases (from `base.nix`): `qgos-update`, `qgos-upgrade`.

---

## Notes & tips

- **Channel:** tracks `nixos-unstable` for a fresh gaming stack. To run stable,
  change `inputs.nixpkgs.url` in `flake.nix` to `nixos-25.05` and point
  home-manager at `release-25.05`.
- **flake.lock:** not committed here; it's created on your first build. Commit it
  afterwards for fully reproducible weekly updates.
- **Streaming to Moonlight:** after boot, open <https://localhost:47990> to pair
  Sunshine with a Moonlight client (phone, tablet, TV, Steam Deck, another PC).
- **In-game overlay:** MangoHud toggles with `Shift_R+F12`; tune it with
  `goverlay`.
- **GPU tuning:** launch **CoreCtrl** for fan curves / undervolting (the
  `amdgpu.ppfeaturemask` kernel flag is already set).
- **NVIDIA/Intel:** this build targets AMD Radeon. Swap `modules/amd.nix` for the
  appropriate driver module if your hardware differs.

---

## labwc keybindings (cheat sheet)

| Keys | Action |
| --- | --- |
| `Super`+`Return` | Terminal (foot) |
| `Super`+`D` | App launcher (wofi) |
| `Super`+`S` | Steam Big Picture |
| `Super`+`W` | Firefox |
| `Super`+`E` | File manager |
| `Super`+`F` / `Super`+`M` | Fullscreen / maximize |
| `Super`+`←/→/↑/↓` | Snap window |
| `Super`+`1..4` | Switch virtual desktop |
| `Print` / `Shift`+`Print` | Screenshot (full / region) |
| `Super`+`L` | Lock screen |
| **Right-click desktop** | The BunsenLabs-style root menu |

---

Game first. 🎮
