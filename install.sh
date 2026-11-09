#!/usr/bin/env bash
#
# QuickGameOS installer
# ---------------------
# Takes a stock (minimal) NixOS install to a full QuickGameOS setup. It can run
# interactively (asking for your username, password and which feature categories
# to enable) or fully unattended with flags.
#
# Run it from a clone of this repo on the machine you want to convert:
#   git clone https://github.com/derikatwork/quickgameos
#   cd quickgameos
#   ./install.sh                         # interactive
#   ./install.sh --profile office -y     # unattended, office preset
#
# It writes hosts/quickgameos/settings.nix (host identity + feature toggles),
# optionally a hashed-password file, regenerates this machine's
# hardware-configuration.nix, then runs `nixos-rebuild switch`. It does NOT
# partition disks or install a bootloader - you already have NixOS.

set -euo pipefail

# --- paths ------------------------------------------------------------------
FLAKE_HOST="quickgameos"
HOST_DIR="hosts/quickgameos"
HW_FILE="$HOST_DIR/hardware-configuration.nix"
SETTINGS_FILE="$HOST_DIR/settings.nix"
PW_FILE="/etc/quickgameos/password.hash"

# --- defaults (the "gaming" profile) ----------------------------------------
USERNAME="gamer"
HOSTNAME_NEW="quickgameos"
TIMEZONE="America/New_York"
PASSWORD=""                 # empty => keep the default "gamer" password
GAMING="true"; STREAMING="true"; OFFICE="false"
DEV="false"; CREATIVE="false"; MODELING="false"
EMULATION="true"; COMMUNICATION="true"; PERIPHERALS="true"; MEDIA="true"
AUTOUPDATE="true"

REGEN_HW="auto"            # auto | yes | no
ASSUME_YES=0
DRY_RUN=0

# --- helpers ----------------------------------------------------------------
c_bold=$'\033[1m'; c_red=$'\033[31m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_rst=$'\033[0m'
info() { printf '%s==>%s %s\n' "$c_grn" "$c_rst" "$*"; }
warn() { printf '%s!! %s%s\n' "$c_yel" "$*" "$c_rst"; }
die()  { printf '%serror:%s %s\n' "$c_red" "$c_rst" "$*" >&2; exit 1; }
run()  { if [ "$DRY_RUN" -eq 1 ]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }
tf()   { case "$1" in 1|y|Y|yes|YES|true) echo true ;; *) echo false ;; esac; }

apply_profile() {
  # Base categories for every profile start off; set the ones this profile wants.
  DEV=false; CREATIVE=false; MODELING=false
  case "$1" in
    gaming)     GAMING=true;  STREAMING=true;  OFFICE=false; EMULATION=true;  COMMUNICATION=true;  PERIPHERALS=true;  MEDIA=true ;;
    office)     GAMING=false; STREAMING=false; OFFICE=true;  EMULATION=false; COMMUNICATION=true;  PERIPHERALS=false; MEDIA=true ;;
    creator)    GAMING=false; STREAMING=true;  OFFICE=false; EMULATION=false; COMMUNICATION=true;  PERIPHERALS=true;  MEDIA=true; CREATIVE=true; MODELING=true ;;
    everything) GAMING=true;  STREAMING=true;  OFFICE=true;  EMULATION=true;  COMMUNICATION=true;  PERIPHERALS=true;  MEDIA=true; DEV=true; CREATIVE=true; MODELING=true ;;
    minimal)    GAMING=false; STREAMING=false; OFFICE=false; EMULATION=false; COMMUNICATION=false; PERIPHERALS=false; MEDIA=false ;;
    *) die "unknown --profile '$1' (gaming|office|creator|everything|minimal)" ;;
  esac
}

usage() {
  cat <<EOF
${c_bold}QuickGameOS installer${c_rst}

Usage: ./install.sh [options]

Identity:
  --username NAME         Primary user (default: gamer)
  --password PASS         Set the user's password (prefer the interactive
                          prompt; a value here is visible in your shell history)
  --hostname NAME         Machine hostname (default: quickgameos)
  --timezone TZ           e.g. America/Los_Angeles

Feature categories (start from a profile, then fine-tune):
  --profile NAME          gaming (default) | office | creator | everything | minimal
  --gaming / --no-gaming
  --streaming / --no-streaming
  --office / --no-office
  --dev / --no-dev
  --creative / --no-creative
  --modeling / --no-modeling
  --emulation / --no-emulation
  --communication / --no-communication
  --peripherals / --no-peripherals
  --media / --no-media
  --no-autoupdate         Disable weekly auto-updates

Other:
  --regen-hardware        Force-regenerate hardware-configuration.nix
  --keep-hardware         Never touch hardware-configuration.nix
  --flake-host NAME       nixosConfigurations.<NAME> to build (default: quickgameos)
  -y, --yes               Non-interactive: use defaults/flags, don't prompt
  --dry-run               Show what would happen; make no changes
  -h, --help              This help

With no --yes and a terminal attached, the installer asks for each of the
above. Flags set the defaults those prompts start from.
EOF
}

# --- parse args -------------------------------------------------------------
# Apply --profile first (in a pre-scan) so individual category flags always
# override it, regardless of argument order.
for ((i = 1; i <= $#; i++)); do
  if [ "${!i}" = "--profile" ]; then
    j=$((i + 1)); apply_profile "${!j:-}"
  fi
done

while [ $# -gt 0 ]; do
  case "$1" in
    --username)       USERNAME="${2:-}"; shift 2 ;;
    --password)       PASSWORD="${2:-}"; shift 2 ;;
    --hostname)       HOSTNAME_NEW="${2:-}"; shift 2 ;;
    --timezone)       TIMEZONE="${2:-}"; shift 2 ;;
    --profile)        shift 2 ;;   # already applied in the pre-scan above
    --gaming)         GAMING=true; shift ;;      --no-gaming)         GAMING=false; shift ;;
    --streaming)      STREAMING=true; shift ;;   --no-streaming)      STREAMING=false; shift ;;
    --office)         OFFICE=true; shift ;;      --no-office)         OFFICE=false; shift ;;
    --dev)            DEV=true; shift ;;          --no-dev)            DEV=false; shift ;;
    --creative)       CREATIVE=true; shift ;;     --no-creative)       CREATIVE=false; shift ;;
    --modeling)       MODELING=true; shift ;;     --no-modeling)       MODELING=false; shift ;;
    --emulation)      EMULATION=true; shift ;;    --no-emulation)      EMULATION=false; shift ;;
    --communication)  COMMUNICATION=true; shift ;; --no-communication) COMMUNICATION=false; shift ;;
    --peripherals)    PERIPHERALS=true; shift ;; --no-peripherals)    PERIPHERALS=false; shift ;;
    --media)          MEDIA=true; shift ;;       --no-media)          MEDIA=false; shift ;;
    --no-autoupdate)  AUTOUPDATE=false; shift ;;
    --regen-hardware) REGEN_HW=yes; shift ;;
    --keep-hardware)  REGEN_HW=no; shift ;;
    --flake-host)     FLAKE_HOST="${2:-}"; shift 2 ;;
    -y|--yes)         ASSUME_YES=1; shift ;;
    --dry-run)        DRY_RUN=1; shift ;;
    -h|--help)        usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
done

# --- locate repo ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
[ -f flake.nix ] || die "run this from the QuickGameOS repo (flake.nix not found)."
[ -f "$SETTINGS_FILE" ] || die "missing $SETTINGS_FILE - is this a full checkout?"
if [ "$DRY_RUN" -ne 1 ]; then
  command -v nixos-rebuild >/dev/null 2>&1 || die "nixos-rebuild not found - this needs to run on NixOS."
  command -v nixos-generate-config >/dev/null 2>&1 || die "nixos-generate-config not found."
fi
if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

# --- interactive prompts ----------------------------------------------------
interactive=0
if [ "$ASSUME_YES" -ne 1 ] && [ "$DRY_RUN" -ne 1 ] && [ -t 0 ]; then interactive=1; fi

ask() { # ask <prompt> <default> -> echoes answer
  local p="$1" d="$2" a=""
  read -r -p "$p [$d]: " a || true
  printf '%s' "${a:-$d}"
}
ask_yn() { # ask_yn <prompt> <true|false> -> echoes true|false
  local p="$1" d="$2" def="n" a=""
  [ "$d" = "true" ] && def="y"
  read -r -p "$p (y/n) [$def]: " a || true
  a="${a:-$def}"; tf "$a"
}
ask_password() {
  local p1="" p2=""
  while :; do
    read -r -s -p "Password for '$USERNAME' (empty = keep default 'gamer'): " p1 || true; echo
    [ -z "$p1" ] && { PASSWORD=""; return; }
    read -r -s -p "Confirm password: " p2 || true; echo
    [ "$p1" = "$p2" ] && { PASSWORD="$p1"; return; }
    warn "passwords didn't match, try again."
  done
}

if [ "$interactive" -eq 1 ]; then
  info "QuickGameOS setup - press Enter to accept the [default]."
  USERNAME="$(ask 'Username' "$USERNAME")"
  ask_password
  HOSTNAME_NEW="$(ask 'Hostname' "$HOSTNAME_NEW")"
  TIMEZONE="$(ask 'Timezone' "$TIMEZONE")"
  echo; info "Feature categories:"
  GAMING="$(ask_yn '  Gaming (Steam, Lutris, Heroic, Bottles, gamescope)' "$GAMING")"
  STREAMING="$(ask_yn '  Streaming (OBS + Sunshine)' "$STREAMING")"
  OFFICE="$(ask_yn '  Office (LibreOffice, Thunderbird, PDF, KeePassXC)' "$OFFICE")"
  DEV="$(ask_yn '  Dev (VS Code, toolchains, Podman, git tooling)' "$DEV")"
  CREATIVE="$(ask_yn '  Creative (GIMP, Krita, Inkscape, Audacity, Kdenlive)' "$CREATIVE")"
  MODELING="$(ask_yn '  3D modelling (Blender, FreeCAD, OpenSCAD, PrusaSlicer)' "$MODELING")"
  EMULATION="$(ask_yn '  Emulation (RetroArch + emulators)' "$EMULATION")"
  COMMUNICATION="$(ask_yn '  Communication (Vesktop/Discord)' "$COMMUNICATION")"
  PERIPHERALS="$(ask_yn '  Peripherals (OpenRGB, Piper, Solaar, Moonlight)' "$PERIPHERALS")"
  MEDIA="$(ask_yn '  Media (mpv, Spotify)' "$MEDIA")"
  AUTOUPDATE="$(ask_yn '  Weekly automatic updates' "$AUTOUPDATE")"
fi

# --- validate ---------------------------------------------------------------
# These values are written verbatim into settings.nix and (for flake-host) into
# the rebuild command, so reject anything that could break or inject.
printf '%s' "$USERNAME" | grep -qE '^[a-z_][a-z0-9_-]*$' \
  || die "invalid username '$USERNAME' (lowercase letters, digits, _ or -)."
printf '%s' "$HOSTNAME_NEW" | grep -qE '^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$' \
  || die "invalid hostname '$HOSTNAME_NEW' (letters, digits, hyphen; max 63)."
printf '%s' "$TIMEZONE" | grep -qE '^[A-Za-z0-9][A-Za-z0-9_+./-]{0,63}$' \
  || die "invalid timezone '$TIMEZONE' (e.g. America/Los_Angeles)."
printf '%s' "$FLAKE_HOST" | grep -qE '^[a-zA-Z0-9._-]+$' \
  || die "invalid --flake-host '$FLAKE_HOST'."

# extras.enable is on if any extras category is on
EXTRAS_ENABLE=false
for v in "$EMULATION" "$COMMUNICATION" "$PERIPHERALS" "$MEDIA"; do
  [ "$v" = "true" ] && EXTRAS_ENABLE=true
done

# --- password hash ----------------------------------------------------------
hash_password() {
  local pw="$1"
  if command -v mkpasswd >/dev/null 2>&1; then
    printf '%s' "$pw" | mkpasswd -m sha-512 -s
  elif command -v openssl >/dev/null 2>&1; then
    printf '%s' "$pw" | openssl passwd -6 -stdin
  else
    printf '%s' "$pw" | nix-shell -p mkpasswd --run "mkpasswd -m sha-512 -s"
  fi
}

HASHED_PW_FILE=""
if [ -n "$PASSWORD" ]; then
  info "Hashing password and writing $PW_FILE (root-only)"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] write sha-512 hash to %s (0600, root)\n' "$PW_FILE"
  else
    HASH="$(hash_password "$PASSWORD")" || die "failed to hash password (need mkpasswd or openssl)."
    $SUDO mkdir -p "$(dirname "$PW_FILE")"
    printf '%s\n' "$HASH" | $SUDO tee "$PW_FILE" >/dev/null
    $SUDO chmod 600 "$PW_FILE"
  fi
  HASHED_PW_FILE="$PW_FILE"
elif [ -e "$PW_FILE" ]; then
  # No new password given, but a hash from a previous run exists - keep using
  # it so a re-run doesn't silently revert the account to the default password.
  info "Keeping existing password hash at $PW_FILE"
  HASHED_PW_FILE="$PW_FILE"
fi

# --- write settings.nix -----------------------------------------------------
info "Writing $SETTINGS_FILE"
pw_line=""
[ -n "$HASHED_PW_FILE" ] && pw_line="    hashedPasswordFile = \"$HASHED_PW_FILE\";"

settings_content="# QuickGameOS settings - generated by ./install.sh (safe to edit by hand).
{ ... }:
{
  networking.hostName = \"$HOSTNAME_NEW\";
  time.timeZone = \"$TIMEZONE\";

  quickgameos = {
    username = \"$USERNAME\";
    desktop = \"cosmic\";
${pw_line}
    gaming.enable = $GAMING;
    streaming.enable = $STREAMING;
    office.enable = $OFFICE;
    dev.enable = $DEV;
    creative.enable = $CREATIVE;
    modeling.enable = $MODELING;

    extras.enable = $EXTRAS_ENABLE;
    extras.emulation = $EMULATION;
    extras.communication = $COMMUNICATION;
    extras.peripherals = $PERIPHERALS;
    extras.media = $MEDIA;

    autoUpdate.enable = $AUTOUPDATE;
  };
}
"
if [ "$DRY_RUN" -eq 1 ]; then
  printf '  [dry-run] would write:\n%s\n' "$settings_content" | sed 's/^/    /'
else
  printf '%s' "$settings_content" > "$SETTINGS_FILE"
fi

# --- hardware configuration -------------------------------------------------
regen=0
case "$REGEN_HW" in
  yes) regen=1 ;;
  no)  regen=0 ;;
  auto) { [ ! -f "$HW_FILE" ] || grep -q "TEMPLATE" "$HW_FILE"; } && regen=1 || info "hardware-configuration.nix already machine-specific; keeping it (use --regen-hardware to override)." ;;
esac
if [ "$regen" -eq 1 ]; then
  info "Generating hardware-configuration.nix for this machine..."
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] nixos-generate-config --show-hardware-config > %s\n' "$HW_FILE"
  else
    [ -f "$HW_FILE" ] && ! grep -q TEMPLATE "$HW_FILE" && cp -v "$HW_FILE" "$HW_FILE.bak.$(date +%s)"
    nixos-generate-config --show-hardware-config > "$HW_FILE"
  fi
fi

# --- summary & build --------------------------------------------------------
echo
info "Summary:"
cat <<EOF
  user        : $USERNAME$( [ -n "$HASHED_PW_FILE" ] && echo " (password set)" || echo " (default 'gamer')")
  hostname    : $HOSTNAME_NEW
  timezone    : $TIMEZONE
  gaming      : $GAMING        streaming : $STREAMING        office : $OFFICE
  dev         : $DEV        creative : $CREATIVE        modeling : $MODELING
  emulation   : $EMULATION        communication : $COMMUNICATION
  peripherals : $PERIPHERALS        media : $MEDIA        auto-update : $AUTOUPDATE
  build       : .#$FLAKE_HOST
EOF

if [ "$ASSUME_YES" -ne 1 ] && [ "$DRY_RUN" -ne 1 ] && [ "$interactive" -eq 1 ]; then
  printf 'Build and switch now? [y/N] '
  read -r reply || true
  case "$reply" in y|Y|yes|YES) ;; *) warn "settings written; skipping the build. Run 'sudo nixos-rebuild switch --flake .#$FLAKE_HOST' when ready."; exit 0 ;; esac
fi

info "Running nixos-rebuild switch (first run downloads a large closure)..."
run "$SUDO nixos-rebuild switch --flake '.#${FLAKE_HOST}' --extra-experimental-features 'nix-command flakes'"

echo
info "${c_bold}QuickGameOS is installed.${c_rst}"
cat <<EOF

Next steps:
  * Reboot into the COSMIC greeter and log in as '$USERNAME'.
$( [ -z "$HASHED_PW_FILE" ] && echo "  * Default password is 'gamer' - run 'passwd' to change it." )
  * Flathub is registered automatically:
      flatpak install flathub com.valvesoftware.Steam   # (optional)

Update anytime with: ${c_bold}qgos-upgrade${c_rst}  (weekly auto-updates are $( [ "$AUTOUPDATE" = true ] && echo on || echo off ))

Game first.
EOF
