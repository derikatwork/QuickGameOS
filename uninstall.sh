#!/usr/bin/env bash
#
# QuickGameOS uninstall / rollback helper
# ---------------------------------------
# On NixOS nothing is "installed" imperatively - the system is a generation you
# can switch between. This helper gives you three ways to back out of
# QuickGameOS:
#
#   1. Roll back to the previous generation  (undo the last `nixos-rebuild`)
#   2. Pick an older generation to activate  (e.g. the one before QuickGameOS)
#   3. Strip to minimal                       (disable every feature category,
#                                              keep the NixOS + COSMIC base)
#
# Run it from a clone of this repo:
#   ./uninstall.sh                 # interactive menu
#   ./uninstall.sh --rollback -y   # undo the last switch, no prompt
#   ./uninstall.sh --list          # just list generations
#   ./uninstall.sh --generation 42
#   ./uninstall.sh --minimal       # disable all categories and rebuild

set -euo pipefail

SYS_PROFILE="/nix/var/nix/profiles/system"

MODE=""          # rollback | generation | minimal | list
GEN=""
ASSUME_YES=0
DRY_RUN=0

c_bold=$'\033[1m'; c_red=$'\033[31m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'; c_rst=$'\033[0m'
info() { printf '%s==>%s %s\n' "$c_grn" "$c_rst" "$*"; }
warn() { printf '%s!! %s%s\n' "$c_yel" "$*" "$c_rst"; }
die()  { printf '%serror:%s %s\n' "$c_red" "$c_rst" "$*" >&2; exit 1; }
run()  { if [ "$DRY_RUN" -eq 1 ]; then printf '  [dry-run] %s\n' "$*"; else eval "$@"; fi; }

usage() {
  cat <<EOF
${c_bold}QuickGameOS uninstall / rollback helper${c_rst}

Usage: ./uninstall.sh [options]

  --rollback            Roll back to the previous system generation
  --generation N        Activate system generation number N
  --list                List system generations and exit
  --minimal             Disable all QuickGameOS feature categories and rebuild
                        (keeps the NixOS + COSMIC base)
  -y, --yes             Don't prompt for confirmation
  --dry-run             Show what would happen; make no changes
  -h, --help            This help

With no mode flag and a terminal attached, you get an interactive menu.
Rollback/generation changes are reversible - just switch to another generation.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --rollback)   MODE="rollback"; shift ;;
    --generation) MODE="generation"; GEN="${2:-}"; shift 2 ;;
    --list)       MODE="list"; shift ;;
    --minimal)    MODE="minimal"; shift ;;
    -y|--yes)     ASSUME_YES=1; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
if [ "$(id -u)" -eq 0 ]; then SUDO=""; else SUDO="sudo"; fi

if [ "$DRY_RUN" -ne 1 ]; then
  command -v nixos-rebuild >/dev/null 2>&1 || die "nixos-rebuild not found - this needs to run on NixOS."
fi

list_generations() {
  if command -v nixos-rebuild >/dev/null 2>&1 && nixos-rebuild list-generations >/dev/null 2>&1; then
    $SUDO nixos-rebuild list-generations
  else
    $SUDO nix-env -p "$SYS_PROFILE" --list-generations
  fi
}

confirm() {
  [ "$ASSUME_YES" -eq 1 ] && return 0
  [ "$DRY_RUN" -eq 1 ] && return 0
  printf '%s [y/N] ' "$1"; read -r r || true
  case "$r" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# --- interactive menu -------------------------------------------------------
if [ -z "$MODE" ]; then
  if [ ! -t 0 ]; then die "no mode given and not interactive (see --help)."; fi
  echo "${c_bold}How do you want to back out of QuickGameOS?${c_rst}"
  echo "  1) Roll back to the previous generation (undo the last switch)"
  echo "  2) Pick an older generation to activate"
  echo "  3) Strip to minimal (disable all feature categories, keep the base)"
  echo "  q) Cancel"
  printf 'Choice [1]: '; read -r choice || true
  case "${choice:-1}" in
    1) MODE="rollback" ;;
    2) MODE="generation" ;;
    3) MODE="minimal" ;;
    q|Q) info "cancelled."; exit 0 ;;
    *) die "invalid choice." ;;
  esac
fi

# --- run --------------------------------------------------------------------
case "$MODE" in
  list)
    list_generations
    ;;

  rollback)
    info "Current generations:"; list_generations || true
    if confirm "Roll back to the PREVIOUS generation now?"; then
      info "Rolling back..."
      run "$SUDO nixos-rebuild switch --rollback"
      info "Done. (Re-run QuickGameOS later with ./install.sh, or roll forward with --generation.)"
    else
      info "cancelled."
    fi
    ;;

  generation)
    if [ -z "$GEN" ]; then
      info "Available generations:"; list_generations || true
      printf 'Generation number to activate: '; read -r GEN || true
    fi
    printf '%s' "$GEN" | grep -qE '^[0-9]+$' || die "invalid generation '$GEN'."
    if confirm "Activate system generation $GEN?"; then
      info "Switching to generation $GEN..."
      run "$SUDO nix-env -p '$SYS_PROFILE' --switch-generation '$GEN'"
      run "$SUDO '$SYS_PROFILE/bin/switch-to-configuration' switch"
      info "Done. Now on generation $GEN."
    else
      info "cancelled."
    fi
    ;;

  minimal)
    [ -x ./install.sh ] || die "install.sh not found next to this script."
    info "Stripping QuickGameOS to minimal (NixOS + COSMIC base, all feature categories off)."
    args=(--profile minimal --keep-hardware)
    [ "$ASSUME_YES" -eq 1 ] && args+=(-y)
    [ "$DRY_RUN" -eq 1 ] && args+=(--dry-run)
    run "./install.sh ${args[*]}"
    ;;
esac
