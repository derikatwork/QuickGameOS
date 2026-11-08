#!/usr/bin/env bash
#
# QuickGameOS installer
# ---------------------
# Takes a stock (minimal) NixOS install to the full QuickGameOS setup:
#   1. generates THIS machine's hardware-configuration.nix,
#   2. optionally sets your username / hostname / timezone,
#   3. applies the flake with `nixos-rebuild switch`.
#
# Run it from a clone of this repo on the machine you want to convert:
#   git clone https://github.com/derikatwork/quickgameos
#   cd quickgameos
#   ./install.sh                 # keep defaults
#   ./install.sh --username alice --timezone America/Los_Angeles
#
# It only touches files in this checkout and runs `nixos-rebuild`; it does
# not partition disks or install a bootloader (you already have NixOS).

set -euo pipefail

# --- defaults ---------------------------------------------------------------
FLAKE_HOST="quickgameos"
HOST_FILE="hosts/quickgameos/default.nix"
HW_FILE="hosts/quickgameos/hardware-configuration.nix"

USERNAME=""
HOSTNAME_NEW=""
TIMEZONE=""
REGEN_HW="auto"      # auto | yes | no
ASSUME_YES=0
DRY_RUN=0

# --- helpers ----------------------------------------------------------------
c_bold=$'\033[1m'; c_red=$'\033[31m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_rst=$'\033[0m'
info()  { printf '%s==>%s %s\n' "$c_grn" "$c_rst" "$*"; }
warn()  { printf '%s!! %s%s\n'  "$c_yel" "$*" "$c_rst"; }
die()   { printf '%serror:%s %s\n' "$c_red" "$c_rst" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
${c_bold}QuickGameOS installer${c_rst}

Usage: ./install.sh [options]

  --username NAME        Set the primary user (default: keep "gamer")
  --hostname NAME        Set the machine hostname (default: keep "quickgameos")
  --timezone TZ          Set the timezone, e.g. America/Los_Angeles
  --regen-hardware       Force-regenerate hardware-configuration.nix
  --keep-hardware        Never touch hardware-configuration.nix
  --flake-host NAME      nixosConfigurations.<NAME> to build (default: quickgameos)
  -y, --yes              Don't prompt for confirmation
  --dry-run              Show what would happen; make no changes
  -h, --help             This help

By default the hardware config is regenerated only if it's still the
checked-in template. Everything else is left as-is unless you pass a flag.
EOF
}

# --- parse args -------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --username)      USERNAME="${2:-}"; shift 2 ;;
    --hostname)      HOSTNAME_NEW="${2:-}"; shift 2 ;;
    --timezone)      TIMEZONE="${2:-}"; shift 2 ;;
    --regen-hardware) REGEN_HW="yes"; shift ;;
    --keep-hardware) REGEN_HW="no"; shift ;;
    --flake-host)    FLAKE_HOST="${2:-}"; shift 2 ;;
    -y|--yes)        ASSUME_YES=1; shift ;;
    --dry-run)       DRY_RUN=1; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
done

run() { if [ "$DRY_RUN" -eq 1 ]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }

# --- sanity checks ----------------------------------------------------------
# Work from the repo root (this script's directory).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

[ -f flake.nix ] || die "run this from the QuickGameOS repo (flake.nix not found)."
[ -f "$HOST_FILE" ] || die "missing $HOST_FILE - is this a full checkout?"
if [ "$DRY_RUN" -ne 1 ]; then
  command -v nixos-rebuild >/dev/null 2>&1 || die "nixos-rebuild not found - this needs to run on NixOS."
  command -v nixos-generate-config >/dev/null 2>&1 || die "nixos-generate-config not found."
fi

if [ -n "$USERNAME" ] && ! printf '%s' "$USERNAME" | grep -qE '^[a-z_][a-z0-9_-]*$'; then
  die "invalid --username '$USERNAME' (use lowercase letters, digits, _ or -)."
fi

# Need root for nixos-rebuild; re-exec steps with sudo as needed.
if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

info "QuickGameOS install from: $SCRIPT_DIR"

# --- 1. hardware configuration ----------------------------------------------
regen=0
case "$REGEN_HW" in
  yes) regen=1 ;;
  no)  regen=0 ;;
  auto)
    if [ ! -f "$HW_FILE" ] || grep -q "TEMPLATE" "$HW_FILE"; then
      regen=1
    else
      info "hardware-configuration.nix already looks machine-specific; keeping it (use --regen-hardware to override)."
    fi
    ;;
esac

if [ "$regen" -eq 1 ]; then
  info "Generating hardware-configuration.nix for this machine..."
  if [ -f "$HW_FILE" ] && ! grep -q "TEMPLATE" "$HW_FILE"; then
    run "cp -v '$HW_FILE' '$HW_FILE.bak.$(date +%s)'"
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] nixos-generate-config --show-hardware-config > %s\n' "$HW_FILE"
  else
    nixos-generate-config --show-hardware-config > "$HW_FILE"
    info "wrote $HW_FILE"
  fi
fi

# --- 2. personalize host config ---------------------------------------------
if [ -n "$USERNAME" ]; then
  info "Setting username = \"$USERNAME\""
  run "sed -i -E 's/(username[[:space:]]*=[[:space:]]*)\"[^\"]*\";/\\1\"$USERNAME\";/' '$HOST_FILE'"
fi

if [ -n "$HOSTNAME_NEW" ]; then
  info "Setting hostname = \"$HOSTNAME_NEW\""
  run "sed -i -E 's/(networking\\.hostName[[:space:]]*=[[:space:]]*)\"[^\"]*\";/\\1\"$HOSTNAME_NEW\";/' '$HOST_FILE'"
fi

if [ -n "$TIMEZONE" ]; then
  info "Setting timezone = \"$TIMEZONE\""
  if grep -q 'time\.timeZone' "$HOST_FILE"; then
    run "sed -i -E 's#(time\\.timeZone[[:space:]]*=[[:space:]]*)\"[^\"]*\";#\\1\"$TIMEZONE\";#' '$HOST_FILE'"
  else
    run "sed -i '/networking\\.hostName/a\\  time.timeZone = \"$TIMEZONE\";' '$HOST_FILE'"
  fi
fi

# --- 3. confirm & build -----------------------------------------------------
echo
info "About to build and switch to ${c_bold}.#${FLAKE_HOST}${c_rst}"
echo "  (first run downloads a large closure - COSMIC, Steam, emulators, ...)"
if [ "$ASSUME_YES" -ne 1 ] && [ "$DRY_RUN" -ne 1 ]; then
  printf 'Proceed? [y/N] '
  read -r reply
  case "$reply" in y|Y|yes|YES) ;; *) die "aborted by user." ;; esac
fi

info "Running nixos-rebuild switch..."
run "$SUDO nixos-rebuild switch --flake '.#${FLAKE_HOST}' --extra-experimental-features 'nix-command flakes'"

# --- done -------------------------------------------------------------------
echo
info "${c_bold}QuickGameOS is installed.${c_rst}"
cat <<EOF

Next steps:
  * Reboot into the COSMIC greeter.
  * Log in (default: ${c_bold}gamer / gamer${c_rst} unless you changed the username)
    and run ${c_bold}passwd${c_rst} to set your own password.
  * Flathub is registered automatically:
      flatpak install flathub com.valvesoftware.Steam   # (optional)

Weekly auto-updates are on. Update now anytime with: ${c_bold}qgos-upgrade${c_rst}

Game first.
EOF
