#!/usr/bin/env bash
set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()     { echo -e "${RED}[ERR]${NC}  $*" >&2; exit 1; }

# ─── Root check ───────────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && die "Run with sudo: sudo bash setup.sh"

# ─── Already have swap? ───────────────────────────────────────────────────────
if swapon --show | grep -q '/swapfile'; then
  warn "Swap already active on /swapfile. Exiting."
  free -h
  exit 0
fi

# ─── Detect RAM ───────────────────────────────────────────────────────────────
RAM_GB=$(awk '/MemTotal/ {printf "%d", $2/1024/1024 + 0.5}' /proc/meminfo)
# Minimum 1 so math doesn't break on 512MB servers (rounds to 0)
[[ $RAM_GB -lt 1 ]] && RAM_GB=1
info "Detected RAM: ${RAM_GB}GB"

# ─── Recommended swap size ────────────────────────────────────────────────────
if   [[ $RAM_GB -le 2 ]]; then DEFAULT_SWAP=$(( RAM_GB * 2 ))
elif [[ $RAM_GB -le 8 ]]; then DEFAULT_SWAP=$RAM_GB
else                           DEFAULT_SWAP=4
fi

# ─── Recommended swappiness (based on RAM) ────────────────────────────────────
# Low RAM servers need higher swappiness to avoid OOM kills
if   [[ $RAM_GB -le 1 ]]; then SWAPPINESS=60
elif [[ $RAM_GB -le 4 ]]; then SWAPPINESS=30
else                           SWAPPINESS=10
fi

# ─── Ask swap size ────────────────────────────────────────────────────────────
read -rp "$(echo -e "${CYAN}Swap size in GB${NC} [default: ${DEFAULT_SWAP}]: ")" SWAP_SIZE
SWAP_SIZE=${SWAP_SIZE:-$DEFAULT_SWAP}
[[ "$SWAP_SIZE" =~ ^[0-9]+$ ]] || die "Invalid size: $SWAP_SIZE"

# ─── Check available disk space ───────────────────────────────────────────────
FREE_GB=$(df / --output=avail -BG | tail -1 | tr -d 'G ')
if [[ $FREE_GB -le $SWAP_SIZE ]]; then
  die "Not enough disk space. Available: ${FREE_GB}GB, Required: ${SWAP_SIZE}GB"
fi

# ─── Create swap file ─────────────────────────────────────────────────────────
info "Creating ${SWAP_SIZE}G swap file at /swapfile ..."
if command -v fallocate &>/dev/null; then
  fallocate -l "${SWAP_SIZE}G" /swapfile
else
  warn "fallocate not available, using dd (slower)..."
  dd if=/dev/zero of=/swapfile bs=1M count=$(( SWAP_SIZE * 1024 )) status=progress
fi

chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
success "Swap file created and activated."

# ─── Persist across reboots ───────────────────────────────────────────────────
if ! grep -q '/swapfile' /etc/fstab; then
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  success "Added swap entry to /etc/fstab"
fi

# ─── Tune kernel params ───────────────────────────────────────────────────────
info "Setting vm.swappiness=${SWAPPINESS} (auto-selected for ${RAM_GB}GB RAM)"
info "Setting vm.vfs_cache_pressure=50"

sysctl -w vm.swappiness=${SWAPPINESS}        > /dev/null
sysctl -w vm.vfs_cache_pressure=50           > /dev/null

grep -qxF "vm.swappiness=${SWAPPINESS}"      /etc/sysctl.conf || echo "vm.swappiness=${SWAPPINESS}"      >> /etc/sysctl.conf
grep -qxF 'vm.vfs_cache_pressure=50'         /etc/sysctl.conf || echo 'vm.vfs_cache_pressure=50'         >> /etc/sysctl.conf

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ''
success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
success "Swap setup complete!"
success "  Size:        ${SWAP_SIZE}GB"
success "  Swappiness:  ${SWAPPINESS} (RAM: ${RAM_GB}GB)"
success "  Cache press: 50"
success "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ''
free -h
swapon --show
