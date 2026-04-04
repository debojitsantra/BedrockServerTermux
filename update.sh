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
SERVER_ZIP="bedrock_server_latest.zip"


for cmd in curl jq unzip wget tar; do
  command -v "$cmd" >/dev/null 2>&1 || {
    info "Installing missing dependency: $cmd"
    apt install -y "$cmd" || error "Failed to install $cmd."
  }
done



mapfile -t SERVER_FOLDERS < <(find "$HOME" -maxdepth 1 -type d -name "server*" | sort)

if [ ${#SERVER_FOLDERS[@]} -eq 0 ]; then
  warn "No existing server folders found. A new one will be created."
fi

# select veersion
echo -e "${BOLD}Select version to install:${RESET}"
echo ""
echo -e "  ${CYAN}1)${RESET} Latest Stable       ${GREEN}(Recommended)${RESET}"
echo -e "  ${CYAN}2)${RESET} Latest Preview/Beta"
echo -e "  ${CYAN}3)${RESET} Specific version    (e.g. 1.26.10.20)"
echo ""
echo -n "Enter choice [1/2/3]: "
read -r VERSION_CHOICE

case "$VERSION_CHOICE" in
  1)
    info "Fetching latest stable URL..."
    DOWNLOAD_URL="$(curl -s "$API_URL" | jq -r '.result.links[] | select(.downloadType=="serverBedrockLinux") | .downloadUrl')"
    DEFAULT_DIR="server"
    VERSION_LABEL="Latest Stable"
    ;;
  2)
    info "Fetching latest preview URL..."
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
    warn "old versions may not work on ARM. If it crashes, use option 1."
    ;;
  *)
    error "Invalid choice."
    ;;
esac

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
  error "Could not resolve download URL. The API may be down."
fi

#select folder
echo ""
echo -e "${BOLD}Select target folder:${RESET}"
echo ""

INDEX=1
for folder in "${SERVER_FOLDERS[@]}"; do
  NAME="$(basename "$folder")"
  if [ "$NAME" = "$DEFAULT_DIR" ]; then
    echo -e "  ${CYAN}${INDEX})${RESET} $NAME  ${GREEN}(default for this version)${RESET}"
  else
    echo -e "  ${CYAN}${INDEX})${RESET} $NAME"
  fi
  INDEX=$((INDEX + 1))
done

echo -e "  ${CYAN}N)${RESET} Create a new folder"
echo ""
echo -n "Enter choice: "
read -r FOLDER_CHOICE

if [[ "$FOLDER_CHOICE" =~ ^[Nn]$ ]]; then
  echo -n "Enter new folder name (default: $DEFAULT_DIR): "
  read -r NEW_FOLDER
  SERVER_DIR="$HOME/${NEW_FOLDER:-$DEFAULT_DIR}"
elif [[ "$FOLDER_CHOICE" =~ ^[0-9]+$ ]] && [ "$FOLDER_CHOICE" -ge 1 ] && [ "$FOLDER_CHOICE" -le ${#SERVER_FOLDERS[@]} ]; then
  SERVER_DIR="${SERVER_FOLDERS[$((FOLDER_CHOICE - 1))]}"
else
  
  SERVER_DIR="$HOME/$DEFAULT_DIR"
fi

echo ""
success "Version : $VERSION_LABEL"
success "Folder  : $SERVER_DIR"
echo ""


mkdir -p "$SERVER_DIR"
cd "$SERVER_DIR"

if [ -d "worlds" ]; then
  TS="$(date +%Y%m%d_%H%M%S)"
  BACKUP_FILE="worlds_backup_${TS}.tar.gz"
  info "Backing up worlds → $BACKUP_FILE ..."
  tar -czf "$BACKUP_FILE" worlds || error "Backup failed. Aborting to protect your worlds."
  success "Backup saved: $BACKUP_FILE"
else
  warn "No 'worlds' directory found — skipping backup."
fi

echo ""


info "Downloading $VERSION_LABEL..."
rm -f "$SERVER_ZIP"
wget -q --show-progress "$DOWNLOAD_URL" -O "$SERVER_ZIP" || error "Download failed."

info "Extracting server files..."
unzip -o "$SERVER_ZIP" || error "Extraction failed."
rm -f "$SERVER_ZIP"

[ -f "bedrock_server" ] && chmod +x bedrock_server && success "bedrock_server marked executable."


info "Updating autostart.sh..."
wget -q https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/refs/heads/main/autostart.sh
chmod +x autostart.sh


cd "$HOME"
info "Updating run script..."
wget -q https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/refs/heads/main/run
chmod +x run


echo ""
echo -e "${GREEN}${BOLD} Update complete!${RESET}"
echo ""
echo -e "  ${BOLD}Version :${RESET} $VERSION_LABEL"
echo -e "  ${BOLD}Folder  :${RESET} $SERVER_DIR"
echo -e "  ${BOLD}Worlds  :${RESET} Backed up (if present)"
echo ""
echo -e "  Start server: ${CYAN}cd ~ && ./run${RESET}"
echo ""
if [ "$VERSION_CHOICE" = "2" ]; then
  warn "Preview/Beta: players need Minecraft Preview client to connect."
fi
if [ "$VERSION_CHOICE" = "3" ]; then
  warn "If the server crashes immediately, this version may be incompatible with your device."
  warn "Run ./update.sh again and choose option 1 to revert to latest stable."
fi
