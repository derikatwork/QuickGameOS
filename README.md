# QuickGameOS

**A Nix-powered, gaming-first OS with the COSMIC desktop — tracking Fedora-level freshness.**

QuickGameOS is a reproducible NixOS flake for a **gaming-first** machine: the
**COSMIC** desktop (System76's fast, Wayland-native DE), AMD Radeon tuned for
Wayland, the full gaming stack (Steam, Lutris, Heroic, Bottles) plus
**Flatpak/Flathub**, a complete streaming setup (OBS + Sunshine), and hands-off
weekly auto-updates.

It stays on **NixOS** but is tuned to track **Fedora-level freshness**: the
flake follows `nixos-unstable` (NixOS's closest analog to Fedora's
bleeding-edge package set, ~Fedora 45-era) and runs the **latest stable
kernel**, the way Fedora ships the newest stable kernel and amdgpu.

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
| **Maintenance** | `nixos-unstable` channel, weekly automatic updates + weekly garbage collection. |

---

## Repository layout

```
flake.nix                      # entry point: `quickgameos` system + `iso` image
modules/
  options.nix                  # the quickgameos.* configuration knobs
  base.nix                     # Nix, GC, fonts, networking, CLI tools, codecs
  amd.nix                      # AMD Radeon + latest stable kernel
  audio.nix                    # PipeWire
  gaming.nix                   # Steam/Lutris/Heroic/Bottles + tooling + MangoHud
  flatpak.nix                  # Flatpak + Flathub remote
  streaming.nix                # OBS + virtual camera + Sunshine
  extras.nix                   # emulation, comms, peripherals, media (toggleable)
  auto-update.nix              # weekly system.autoUpgrade
  users.nix                    # the primary user
  desktop/default.nix          # COSMIC desktop + greeter
hosts/quickgameos/
  default.nix                  # the installed machine (bootloader, hostname)
  hardware-configuration.nix   # TEMPLATE — replace with YOUR hardware
iso/default.nix                # lean COSMIC live/installer image (embeds the flake)
.github/workflows/check.yml    # CI: format check + evaluate both configs
.github/workflows/build-iso.yml# CI: build the downloadable ISO + config bundle
```

---

## Quick start

### Option A — get the downloadable ISO

The ISO is a **lean COSMIC live/installer image**: it boots a COSMIC live
session with the installer and the whole QuickGameOS flake embedded, and you
install the *full* stack to disk from it.

**Download a prebuilt ISO (no Nix needed):** repo's **Actions → build-iso**,
run the workflow (or open the latest run), and download the **`quickgameos-iso`**
artifact (the `.iso`, `SHA256SUMS.txt`, and a `quickgameos-config.tar.gz`
bundle). Tagged releases (`git tag v0.1.0 && git push --tags`) attach the same
files to a GitHub Release.

**Or build it yourself (needs Nix):**

```bash
nix build .#iso
# image lands in ./result/iso/quickgameos-*.iso
```

Write it to USB (`sudo dd if=quickgameos-*.iso of=/dev/sdX bs=4M status=progress oflag=sync`,
or Ventoy/balenaEtcher) and boot it. It auto-logs into the COSMIC live desktop;
follow `/etc/quickgameos-install/INSTALL.txt` to install to disk.

### Option B — install to disk from the flake

1. Boot the live ISO and get the flake (`git clone https://github.com/derikatwork/quickgameos`).
2. Partition/format/mount your target (`/mnt`, ESP at `/mnt/boot`).
3. **Generate this machine's hardware config** (required — the checked-in one is a non-booting template):
   ```bash
   sudo nixos-generate-config --root /mnt --show-hardware-config \
     > hosts/quickgameos/hardware-configuration.nix
   ```
4. Install: `sudo nixos-install --flake .#quickgameos`
5. Reboot, log in as **`gamer`** / **`gamer`**, and run `passwd`.

### Option C — apply to an existing NixOS machine

```bash
# after replacing hardware-configuration.nix as in step 3 above:
sudo nixos-rebuild switch --flake .#quickgameos
```

---

## Configuration knobs

Everything user-facing lives under `quickgameos.*` (see `modules/options.nix`),
set in `hosts/quickgameos/default.nix`:

```nix
quickgameos = {
  username = "gamer";
  desktop  = "cosmic";       # COSMIC (Wayland)

  gaming.enable    = true;
  streaming.enable = true;

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
