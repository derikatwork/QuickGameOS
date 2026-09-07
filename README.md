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
| **Extras** | Emulation (RetroArch + standalone emulators + ES-DE frontend), Vesktop (Wayland Discord), OpenRGB/Piper/Solaar peripheral tools, a Moonlight client, mpv + Spotify. All toggleable. |
| **Maintenance** | Stable `nixos-25.05` channel, weekly automatic updates + weekly garbage collection. |

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
  extras.nix                   # emulation, comms, peripherals, media (toggleable)
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
iso/default.nix                # lean live/installer image (embeds the flake)
.github/workflows/check.yml    # CI: format check + evaluate both configs
.github/workflows/build-iso.yml# CI: build the downloadable ISO + config bundle
```

---

## Quick start

### Option A — get the downloadable ISO

The ISO is a **lean installer/live image**: it boots a themed labwc live
session with the installer and the whole QuickGameOS flake embedded, and you
install the *full* stack (Steam, Plasma, emulators, streaming, …) to disk from
it. Keeping it lean is what lets it build on CI and stay a reasonable download.

**Download a prebuilt ISO (no Nix needed):**

- Go to the repo's **Actions → build-iso**, run the workflow (or open the latest
  run), and download the **`quickgameos-iso`** artifact — it contains the `.iso`,
  a `SHA256SUMS.txt`, and a `quickgameos-config.tar.gz` config bundle.
- Or, for tagged releases (`git tag v0.1.0 && git push --tags`), the same files
  are attached to the **GitHub Release**.

**Or build it yourself (needs Nix):**

```bash
nix build .#iso
# image lands in ./result/iso/quickgameos-*.iso
```

Write it to a USB stick (`sudo dd if=quickgameos-*.iso of=/dev/sdX bs=4M
status=progress oflag=sync`, or Ventoy/balenaEtcher) and boot it. It auto-logs
into the labwc live desktop; follow `/etc/quickgameos-install/INSTALL.txt` to
install QuickGameOS to your drive.

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

  # Extras (all default true; flip any off you don't want):
  extras.enable        = true;
  extras.emulation     = true;   # RetroArch + emulators + ES-DE
  extras.communication = true;   # Vesktop (Discord)
  extras.peripherals   = true;   # OpenRGB, Piper, Solaar, Moonlight client
  extras.media         = true;   # mpv, Spotify

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

- **Channel:** tracks stable `nixos-25.05` for steadier weekly updates. For the
  very newest gaming packages instead, change `inputs.nixpkgs.url` in `flake.nix`
  to `nixos-unstable` and point home-manager at its default branch.
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
