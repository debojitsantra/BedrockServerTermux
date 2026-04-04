#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[*]${RESET} $1"; }
success() { echo -e "${GREEN}[✓]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $1"; }
error()   { echo -e "${RED}[✗]${RESET} $1"; exit 1; }



info "Granting storage access..."
termux-setup-storage

info "Updating Termux packages..."
apt update -y && apt upgrade -y || error "Failed to update packages."

info "Installing proot-distro..."
pkg install proot-distro -y || error "Failed to install proot-distro."

info "Installing Debian via proot-distro..."
proot-distro install debian || error "Debian installation failed. Check your internet or storage."

info "Creating 'pdd' shortcut command..."
echo "proot-distro login debian" > /data/data/com.termux/files/usr/bin/pdd
chmod +x /data/data/com.termux/files/usr/bin/pdd

echo ""
echo -e "${GREEN}${BOLD} Termux setup complete!${RESET}"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo -e "  1. Type ${CYAN}pdd${RESET} to enter Debian"
echo -e "  2. Inside Debian, run:"
echo -e "     ${CYAN}curl -fsSL https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/main/setup_env.sh | bash${RESET}"
echo ""
