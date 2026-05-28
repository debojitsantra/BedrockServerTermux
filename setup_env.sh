#!/bin/bash
set -euo pipefail

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

API_URL="https://net-secondary.web.minecraft-services.net/api/v1.0/download/links"




info "Updating packages..."
apt update -y && apt upgrade -y

info "Installing dependencies..."
apt install -y git box64 sudo jq unzip tar curl wget gpg || error "Failed to install required packages."


info "Installing Playit (portable daemon and CLI)..."
curl -SsL -o /usr/local/bin/playitd https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-aarch64 || warn "Playit daemon installation failed."
curl -SsL -o /usr/local/bin/playit-cli https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-cli-linux-aarch64 || warn "Playit CLI installation failed."
chmod +x /usr/local/bin/playitd /usr/local/bin/playit-cli 2>/dev/null || true

#version
echo ""
echo -e "${BOLD}Select Bedrock server version to install:${RESET}"
echo ""
echo -e "  ${CYAN}1)${RESET} Latest Stable       ${GREEN}(Recommended)${RESET}"
echo -e "  ${CYAN}2)${RESET} Latest Preview/Beta"
echo -e "  ${CYAN}3)${RESET} Specific version    (e.g. 1.26.10.20)"
echo ""
echo -n "Enter choice [1/2/3]: "
read -r VERSION_CHOICE

case "$VERSION_CHOICE" in
  1)
    info "Fetching latest stable download URL..."
    DOWNLOAD_URL="$(curl -s "$API_URL" | jq -r '.result.links[] | select(.downloadType=="serverBedrockLinux") | .downloadUrl')"
    DEFAULT_DIR="server"
    VERSION_LABEL="Latest Stable"
    ;;
  2)
    info "Fetching latest preview download URL..."
    DOWNLOAD_URL="$(curl -s "$API_URL" | jq -r '.result.links[] | select(.downloadType=="serverBedrockPreviewLinux") | .downloadUrl')"
    DEFAULT_DIR="server_preview"
    VERSION_LABEL="Latest Preview"
    ;;
  3)
    echo ""
    echo -n "Enter version number (e.g. 1.26.10.4): "
    read -r CUSTOM_VERSION
    DOWNLOAD_URL="https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-${CUSTOM_VERSION}.zip"
    DEFAULT_DIR="server_${CUSTOM_VERSION}"
    VERSION_LABEL="$CUSTOM_VERSION"
    warn "old versions are not guaranteed to work on ARM. If it crashes, try latest stable."
    ;;
  *)
    error "Invalid choice."
    ;;
esac

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
  error "Could not resolve download URL. The API may be down."
fi

#selwct folder
echo ""
echo -e "  Install directory ${CYAN}(default: ~/${DEFAULT_DIR})${RESET}"
echo -n "  Press Enter to use default or type a folder name: "
read -r CUSTOM_DIR

SERVER_DIR="$HOME/${CUSTOM_DIR:-$DEFAULT_DIR}"

if [ -d "$SERVER_DIR" ]; then
  warn "Directory '$SERVER_DIR' already exists. Files will be overwritten."
fi

echo ""
success "Version : $VERSION_LABEL"
success "Folder  : $SERVER_DIR"
echo ""


mkdir -p "$SERVER_DIR"
cd "$SERVER_DIR"

info "Downloading Bedrock server..."
wget -q --show-progress "$DOWNLOAD_URL" -O bedrock_server_latest.zip || error "Download failed."

info "Extracting..."
unzip -o bedrock_server_latest.zip || error "Extraction failed."
rm -f bedrock_server_latest.zip
chmod +x bedrock_server


info "Downloading autostart.sh..."
wget -q https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/refs/heads/main/autostart.sh
chmod +x autostart.sh


cd "$HOME"

info "Downloading run script..."
wget -q https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/refs/heads/main/run
chmod +x run

info "Downloading update script..."
wget -q https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/refs/heads/main/update.sh
chmod +x update.sh


echo ""
echo -e "${GREEN}${BOLD} Setup complete!${RESET}"
echo ""
echo -e "  ${BOLD}Version :${RESET} $VERSION_LABEL"
echo -e "  ${BOLD}Folder  :${RESET} $SERVER_DIR"
echo ""
echo -e "  ${BOLD}Start server:${RESET}   ${CYAN}cd ~ && ./run${RESET}"
echo -e "  ${BOLD}Update server:${RESET}  ${CYAN}./update.sh${RESET}"
echo ""
if [ "$VERSION_CHOICE" = "2" ]; then
  warn "Preview/Beta: players need Minecraft Preview client to connect."
fi
