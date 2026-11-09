# QuickGameOS

**A Nix-powered, gaming-first NixOS configuration with the COSMIC desktop — tracking Fedora-level freshness.**

QuickGameOS is a reproducible **NixOS flake** that turns a plain NixOS install
into a **gaming-first** machine: the **COSMIC** desktop (System76's fast,
Wayland-native DE), AMD Radeon tuned for Wayland, the full gaming stack (Steam,
Lutris, Heroic, Bottles) plus **Flatpak/Flathub**, a complete streaming setup
(OBS + Sunshine), and hands-off weekly auto-updates.

It stays on **NixOS** but is tuned to track **Fedora-level freshness**: the
flake follows `nixos-unstable` (NixOS's closest analog to Fedora's
bleeding-edge package set, ~Fedora 45-era) and runs the **latest stable
kernel**, the way Fedora ships the newest stable kernel and amdgpu.

> This repo is a **configuration + guide**, not an ISO. You install stock NixOS
> from the official minimal image, then apply this flake to go from minimal to
> the complete QuickGameOS setup (see the guide below).

> Note on "same versions as Fedora": NixOS packages independently from Fedora,
> so exact version parity isn't guaranteed — but tracking `nixos-unstable` +
> `linuxPackages_latest` keeps the kernel and software at the same upstream
> freshness Fedora targets. Pin `inputs.nixpkgs` to a stable release
> (e.g. `nixos-25.11`) if you'd rather trade freshness for stability.

---

## What you get

| Area | Included |
| --- | --- |
| **Desktop** | **COSMIC** (Wayland-native) with `cosmic-greeter`. COSMIC owns its own theming/settings. |
| **GPU** | AMD Radeon on Wayland: amdgpu + Mesa/RADV, 32-bit userspace, **latest stable kernel**, CoreCtrl + `hardware.amdgpu.overdrive` for tuning, VRR-ready. |
| **Gaming** | Native Steam (+ Proton-GE, gamescope session, GameMode), Lutris, Heroic, Bottles, MangoHud + GOverlay, vkBasalt, ProtonUp-Qt, controllers — **plus Flatpak/Flathub** for the Flatpak editions. |
| **Streaming** | OBS (COSMIC/PipeWire screen capture via the portal + AMD VAAPI encode + virtual camera); Sunshine host for Moonlight remote play. |
| **Audio** | PipeWire (low-latency, per-app routing), qpwgraph/Helvum, EasyEffects. |
| **Extras** | Emulation (RetroArch + emulators), Vesktop, OpenRGB/Piper/Solaar, Moonlight client, mpv + Spotify. All toggleable. |
| **Office** | Optional productivity category: LibreOffice, Thunderbird, PDF viewer, KeePassXC (off by default). |
| **Dev** | Optional developer category: VS Code, Neovim, C/C++/Python/Node/Go/Rust toolchains, rootless Podman, `gh`/`lazygit` (off by default). |
| **Creative** | Optional content-creation category: GIMP, Krita, Inkscape, darktable, Audacity, Kdenlive, HandBrake (off by default). |
| **3D modelling** | Optional category: Blender, FreeCAD, OpenSCAD, MeshLab, PrusaSlicer (off by default). |
| **Maintenance** | `nixos-unstable` channel, weekly automatic updates + weekly garbage collection. |

---

## From minimal NixOS to full QuickGameOS

You go from a bare machine to the complete setup in a few steps.

### Quick install (script)

Already on NixOS and just want it done? From a clone of this repo:

```bash
nix-shell -p git
git clone https://github.com/derikatwork/quickgameos
cd quickgameos
./install.sh                         # interactive: asks username, password & categories
```

Run with no flags (and a terminal attached) and it **asks you** for:

- **Username** and **password** (hidden; hashed with `mkpasswd`/`openssl` and
  written to a root-only `/etc/quickgameos/password.hash` — never committed),
- **Hostname** and **timezone**,
- which **feature categories** to turn on: Gaming, Streaming, Office, Dev,
  Creative, 3D modelling, Emulation, Communication, Peripherals, Media, and
  weekly auto-updates.

Prefer presets or unattended runs? Start from a **profile** and fine-tune:

```bash
./install.sh --profile office -y                 # office preset, no prompts
./install.sh --profile creator --dev             # content-creation + dev
./install.sh --profile gaming --no-emulation     # gaming, but skip emulators
./install.sh --username alice --timezone America/Los_Angeles --office
```

Profiles: `gaming` (default) · `office` · `creator` · `everything` · `minimal`.
Per-category flags (`--gaming`/`--no-gaming`, `--dev`/`--no-dev`,
`--creative`, `--modeling`, …) override the profile. Other useful flags:
`--password`, `--hostname`, `--dry-run` (preview),
`--keep-hardware`/`--regen-hardware`, `-y/--yes`, `--help`.

The installer writes your choices to `hosts/quickgameos/settings.nix`,
regenerates this machine's `hardware-configuration.nix`, then runs
`nixos-rebuild switch --flake .#quickgameos`. It does **not** partition disks or
install a bootloader — you already have NixOS. Prefer doing it by hand? Follow
the manual steps below.

### Manual steps

#### 1. Install stock NixOS (minimal)

Grab the official **minimal ISO** from <https://nixos.org/download> (any recent
NixOS installer works), boot it, and do a normal install — partition, mount,
`nixos-generate-config`, `nixos-install`, set a root password, reboot. Nothing
QuickGameOS-specific yet; this is just vanilla NixOS. (Already running NixOS?
Skip to step 2.)

#### 2. Get the flake

```bash
nix-shell -p git        # if git isn't installed yet
git clone https://github.com/derikatwork/quickgameos
cd quickgameos
```

#### 3. Drop in this machine's hardware config

The checked-in `hosts/quickgameos/hardware-configuration.nix` is a **non-booting
template** — replace it with the one generated for *your* hardware:

```bash
sudo nixos-generate-config --show-hardware-config \
  > hosts/quickgameos/hardware-configuration.nix
```

#### 4. Make it yours (optional)

Edit `hosts/quickgameos/settings.nix` — set your `quickgameos.username`,
hostname, timezone, and flip any feature category you don't want (see
**Configuration knobs** below). This is the same file `install.sh` generates,
so hand-editing and the script are interchangeable.

#### 5. Switch to QuickGameOS

```bash
sudo nixos-rebuild switch --flake .#quickgameos
```

This pulls in COSMIC, the gaming + streaming stacks, AMD tuning, Flatpak/Flathub,
and the weekly auto-update timer — all at once. First build downloads a lot; grab
a coffee.

#### 6. Reboot & finish

Reboot into the COSMIC greeter, log in as your user (default **`gamer`** /
**`gamer`** if you kept the defaults), then:

```bash
passwd                              # set your own password immediately
flatpak install flathub com.valvesoftware.Steam   # (optional) Flatpak editions
```

That's it — you're on the complete QuickGameOS setup. From here it keeps itself
updated weekly.

#### Ongoing

- **Update now:** `qgos-upgrade` (alias for `nixos-rebuild switch --flake … --upgrade`).
- **Weekly auto-updates** run on their own; set `quickgameos.autoUpdate.flake`
  to your own fork so the machine tracks a config you control (see below).

---

## Uninstall / rollback

NixOS keeps every build as a *generation* you can switch between, so backing out
is safe and reversible. Use `./uninstall.sh` (interactive menu, or flags):

```bash
./uninstall.sh --rollback        # undo the last switch (previous generation)
./uninstall.sh --list            # list system generations
./uninstall.sh --generation 42   # activate a specific generation (e.g. pre-QuickGameOS)
./uninstall.sh --minimal         # disable every feature category, keep the NixOS + COSMIC base
```

Quick aliases are also installed: **`qgos-rollback`** (previous generation) and
**`qgos-generations`** (list them). To go all the way back to a plain system,
roll back to the generation from *before* you first ran `install.sh`. None of
this deletes data — switching generations is reversible, and you can re-apply
QuickGameOS anytime with `./install.sh`.

---

## Configuration knobs

Everything user-facing lives under `quickgameos.*` (see `modules/options.nix`),
set in `hosts/quickgameos/settings.nix` (the file `install.sh` regenerates):

```nix
quickgameos = {
  username = "gamer";
  desktop  = "cosmic";       # COSMIC (Wayland)

  gaming.enable    = true;
  streaming.enable = true;
  office.enable    = false;  # LibreOffice, Thunderbird, PDF, KeePassXC
  dev.enable       = false;  # VS Code, toolchains, Podman, git tooling
  creative.enable  = false;  # GIMP, Krita, Inkscape, Audacity, Kdenlive
  modeling.enable  = false;  # Blender, FreeCAD, OpenSCAD, PrusaSlicer

  # Extras (all default true; flip any off):
  extras.enable        = true;
  extras.emulation     = true;   # RetroArch + emulators
  extras.communication = true;   # Vesktop (Discord)
  extras.peripherals   = true;   # OpenRGB, Piper, Solaar, Moonlight client
  extras.media         = true;   # mpv, Spotify

  autoUpdate = {
    enable = true;
    flake  = "github:derikatwork/quickgameos#quickgameos";
    allowReboot = false;       # true lets kernel updates reboot at 04:00–06:00
  };
};
```

---

## Repository layout

```
flake.nix                      # entry point: the `quickgameos` system
install.sh                     # minimal NixOS -> full QuickGameOS installer
uninstall.sh                   # rollback / strip-to-minimal helper
modules/
  options.nix                  # the quickgameos.* configuration knobs
  base.nix                     # Nix, GC, fonts, networking, CLI tools, codecs
  amd.nix                      # AMD Radeon + latest stable kernel
  audio.nix                    # PipeWire
  gaming.nix                   # Steam/Lutris/Heroic/Bottles + tooling + MangoHud
  flatpak.nix                  # Flatpak + Flathub remote
  streaming.nix                # OBS + virtual camera + Sunshine
  office.nix                   # office / productivity category (opt-in)
  dev.nix                      # developer category (opt-in)
  creative.nix                 # creative / content-creation category (opt-in)
  modeling.nix                 # 3D modelling category (opt-in)
  extras.nix                   # emulation, comms, peripherals, media (toggleable)
  auto-update.nix              # weekly system.autoUpgrade
  users.nix                    # the primary user
  desktop/default.nix          # COSMIC desktop + greeter
hosts/quickgameos/
  default.nix                  # bootloader, imports (host wiring)
  settings.nix                 # host identity + feature toggles (install.sh writes this)
  hardware-configuration.nix   # TEMPLATE — replace with YOUR hardware
.github/workflows/check.yml    # CI: evaluate the config + nixpkgs-fmt (advisory)
```

---

## Notes & tips

- **Channel / "Fedora versions":** tracks `nixos-unstable` for Fedora-level
  freshness and `linuxPackages_latest` for the newest stable kernel. Change
  `inputs.nixpkgs.url` in `flake.nix` to pin a stable release instead.
- **Flatpak:** Flathub is registered on first boot, so `flatpak install flathub <app>`
  and the COSMIC Store work out of the box — install Steam/Lutris/Heroic/Bottles/OBS
  as Flatpaks if you prefer them to the native builds.
- **Codecs (the "RPM Fusion" bit):** `allowUnfree` + full media codecs are on, so
  proprietary audio/video just works.
- **Streaming to Moonlight:** after boot, open <https://localhost:47990> to pair
  Sunshine with a Moonlight client.
- **In-game overlay:** MangoHud toggles with `Shift_R+F12`; tune it with `goverlay`.
- **GPU tuning:** launch **CoreCtrl** for fan curves / undervolting.
- **NVIDIA/Intel:** this build targets AMD Radeon. Swap `modules/amd.nix` for the
  appropriate driver module if your hardware differs.

---

Game first. 🎮
