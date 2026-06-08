#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# ZCU104 Setup Script
# - Updates the system packages
# - Configures a static IP address (auto-detected from current network)
#
# Usage:
#   1. Copy the script to the board:
#        scp setup.sh xilinx@<board-ip>:~/
#   2. Run:
#        ssh xilinx@<board-ip>
#        chmod +x setup.sh
#        sudo ./setup.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[DONE]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()    { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo -e "${BOLD}Usage:${NC} sudo $0"
            echo ""
            echo "  Detects the current IP and configures it as a static address."
            exit 0
            ;;
        *) fail "Unknown option: $1" ;;
    esac
done

# ── Checks ───────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    fail "This script must be run as root (use sudo)"
fi

echo -e "\n${BOLD}${CYAN}════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}   ZCU104 Setup${NC}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════${NC}\n"

# ── Step 1: System update ────────────────────────────────────────────────────
info "Updating system packages..."
apt-get update -y
apt-get upgrade -y
success "System packages updated"

# ── Step 2: Update Python packages ───────────────────────────────────────────
if pip3 show pynq &>/dev/null; then
    info "Upgrading pynq Python package..."
    pip3 install --upgrade pynq
    success "pynq package updated"
fi

# ── Step 3: Install useful packages ──────────────────────────────────────────
info "Installing useful packages..."
apt-get install -y curl wget htop net-tools openssh-server rsync lm-sensors i2c-tools \
                   git cmake build-essential
success "Packages installed"

# Power-rail sanity check: no hwmon rails means the kernel image lacks the PMBus / ina2xx drivers or DT nodes (see docs/).
info "Detected hwmon rails (for energy measurement):"
if ls /sys/class/hwmon/hwmon* >/dev/null 2>&1; then
    for h in /sys/class/hwmon/hwmon*; do
        name=$(cat "$h/name" 2>/dev/null || echo "?")
        chans=$(ls "$h" 2>/dev/null | grep -E '^(power|in|curr)[0-9]+_input$' | wc -l)
        echo "   $(basename "$h"): ${name} (${chans} channel file(s))"
    done
else
    warn "No hwmon devices found — live power readings will be unavailable"
fi

# ── Step 3b: Build & install ASTRON PMT ──────────────────────────────────────
# Benchmarks link libpmt; its "xilinx" backend is a generic hwmon power*_input reader, works on ZCU104 unchanged.
PMT_SRC_DIR="${PMT_SRC_DIR:-/home/xilinx/pmt}"
PMT_REPO="${PMT_REPO:-https://git.astron.nl/RD/pmt.git}"
if [[ ! -f /usr/local/lib/libpmt.so && ! -f /usr/local/lib/libpmt.a ]]; then
    info "Building ASTRON PMT (one-time)..."
    if [[ ! -d "$PMT_SRC_DIR/.git" ]]; then
        git clone "$PMT_REPO" "$PMT_SRC_DIR"
    else
        info "PMT sources already present at $PMT_SRC_DIR"
    fi
    mkdir -p "$PMT_SRC_DIR/build"
    (
        cd "$PMT_SRC_DIR/build"
        cmake .. -DPMT_BUILD_XILINX=ON -DCMAKE_INSTALL_PREFIX=/usr/local
        make -j"$(nproc)"
        make install
    )
    ldconfig
    success "PMT built and installed to /usr/local"
else
    info "PMT already installed at /usr/local — skipping build"
fi

# ── Step 4: Enable SSH ───────────────────────────────────────────────────────
info "Enabling SSH server..."
systemctl enable ssh
systemctl start ssh
success "SSH enabled and running"

# ── Step 5: Passwordless sudo for xilinx user ────────────────────────────────
SUDOERS_FILE="/etc/sudoers.d/xilinx-nopasswd"
if [[ ! -f "$SUDOERS_FILE" ]]; then
    info "Enabling passwordless sudo for xilinx user..."
    echo "xilinx ALL=(ALL) NOPASSWD: ALL" > "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
    success "Passwordless sudo enabled for xilinx"
else
    warn "Passwordless sudo already configured"
fi

# ── Step 6: Configure static IP ──────────────────────────────────────────────
info "Detecting network configuration..."

# Auto-detect the first active Ethernet interface
IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(eth|en)' | head -n1)
if [[ -z "$IFACE" ]]; then
    fail "No Ethernet interface found"
fi
info "Detected interface: $IFACE"

# Get current IPv4 address with prefix length (e.g. 192.168.1.100/24)
CURRENT_IP_CIDR=$(ip -4 addr show "$IFACE" | grep -oP 'inet \K[\d./]+' | head -n1)
if [[ -z "$CURRENT_IP_CIDR" ]]; then
    fail "No IPv4 address found on $IFACE"
fi
STATIC_IP=$(echo "$CURRENT_IP_CIDR" | cut -d'/' -f1)
PREFIX_LEN=$(echo "$CURRENT_IP_CIDR" | cut -d'/' -f2)
info "Current IP: $STATIC_IP/$PREFIX_LEN"

# Detect default gateway
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -n1)
if [[ -z "$GATEWAY" ]]; then
    warn "No default gateway detected, static config will have no gateway"
fi
info "Gateway: ${GATEWAY:-none}"

# Detect DNS servers (skip 127.0.0.53 which is the systemd-resolved stub)
DNS_SERVERS=$(grep -E '^nameserver' /etc/resolv.conf | awk '{print $2}' | grep -v '127.0.0' | head -n3 | tr '\n' ',' | sed 's/,$//')
if [[ -z "$DNS_SERVERS" ]]; then
    DNS_SERVERS="8.8.8.8,8.8.4.4"
    warn "No real DNS servers found, defaulting to $DNS_SERVERS"
fi
info "DNS: $DNS_SERVERS"

# Write static IP configuration via /etc/network/interfaces
# (PynqLinux does not use systemd-networkd, so netplan won't work properly)
info "Configuring static IP via /etc/network/interfaces..."

NETMASK=$(python3 -c "import ipaddress; print(ipaddress.IPv4Network('0.0.0.0/${PREFIX_LEN}').netmask)" 2>/dev/null || echo "255.255.255.0")

# Remove any existing netplan configs that might conflict
if [[ -d /etc/netplan ]]; then
    rm -f /etc/netplan/*.yaml
    warn "Removed netplan configs to avoid conflicts"
fi

# Write the static interface config
cat > /etc/network/interfaces <<IFACES_EOF
# Loopback
auto lo
iface lo inet loopback

# Static IP for ${IFACE}
auto ${IFACE}
iface ${IFACE} inet static
    address ${STATIC_IP}
    netmask ${NETMASK}
$(if [[ -n "$GATEWAY" ]]; then echo "    gateway ${GATEWAY}"; fi)
    dns-nameservers ${DNS_SERVERS//,/ }
IFACES_EOF

# Restart networking
ifdown "$IFACE" 2>/dev/null || true
ifup "$IFACE" 2>/dev/null || true
success "Static IP configured via /etc/network/interfaces"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}   Setup Complete!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}Static IP:${NC}     ${CYAN}${STATIC_IP}/${PREFIX_LEN}${NC}"
echo -e "  ${BOLD}Interface:${NC}     ${CYAN}${IFACE}${NC}"
echo -e "  ${BOLD}Gateway:${NC}       ${CYAN}${GATEWAY:-none}${NC}"
echo -e "  ${BOLD}DNS:${NC}           ${CYAN}${DNS_SERVERS}${NC}"
echo -e "  ${BOLD}Hostname:${NC}      ${CYAN}$(hostname)${NC}"
echo ""
echo -e "  ${BOLD}Connect via:${NC}"
echo -e "    ssh xilinx@${STATIC_IP}"
echo ""
echo -e "  ${BOLD}Jupyter Notebook:${NC}"
echo -e "    http://${STATIC_IP}:9090"
echo ""
