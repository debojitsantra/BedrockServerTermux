#!/data/data/com.termux/files/usr/bin/bash
set -e

# config
API_URL="https://net-secondary.web.minecraft-services.net/api/v1.0/download/links"
SERVER_ZIP="bedrock_server_latest.zip"

# check required commands 
need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command '$1' not found. Installing..."
    pkg install -y "$1" || {
      echo "Failed to install '$1'. Install it manually and rerun this script."
      exit 1
    }
  fi
}

cd "$(dirname "$0")"

echo "Checking dependencies..."
need_cmd curl
need_cmd jq
need_cmd unzip
need_cmd wget
need_cmd tar

echo ""
echo "========================================="
echo "  Minecraft Bedrock Server Update Tool"
echo "========================================="
echo ""
echo "Choose which version to install:"
echo ""
echo "  1) Stable (Recommended for most servers)"
echo ""
echo "  2) Preview/Beta"
echo ""
echo -n "Enter your choice (1 or 2): "
read -r VERSION_CHOICE

case "$VERSION_CHOICE" in
  1)
    DOWNLOAD_TYPE="serverBedrockLinux"
    VERSION_NAME="Stable"
    ;;
  2)
    DOWNLOAD_TYPE="serverBedrockPreviewLinux"
    VERSION_NAME="Preview/Beta"
    ;;
  *)
    echo ""
    echo " Invalid choice. Please run the script again and choose 1 or 2."
    exit 1
    ;;
esac

echo ""
echo " Selected: $VERSION_NAME version"
echo ""
echo "Fetching latest Bedrock server download URL from Mojang..."

DOWNLOAD_URL="$(
  curl -s "$API_URL" \
  | jq -r ".result.links[] | select(.downloadType==\"$DOWNLOAD_TYPE\") | .downloadUrl"
)"

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
  echo " Could not get latest Bedrock server download URL."
  echo "   The API may have changed or is down."
  echo "   Download type requested: $DOWNLOAD_TYPE"
  exit 1
fi

echo " Found latest $VERSION_NAME server URL:"
echo "   $DOWNLOAD_URL"
echo ""

# backup
if [ -d "worlds" ]; then
  TS="$(date +%Y%m%d_%H%M%S)"
  BACKUP_FILE="worlds_backup_${TS}.tar.gz"
  echo " Backing up 'worlds' directory to $BACKUP_FILE ..."
  tar -czf "$BACKUP_FILE" worlds || {
    echo "❌ Failed to create backup. Aborting to avoid data loss."
    exit 1
  }
  echo " Backup complete."
  echo ""
else
  echo "  No 'worlds' directory found. Skipping world backup."
  echo ""
fi

# download
echo "  Downloading latest $VERSION_NAME Bedrock server..."
rm -f "$SERVER_ZIP"

wget -q --show-progress "$DOWNLOAD_URL" -O "$SERVER_ZIP" || {
  echo " Failed to download Bedrock server ZIP."
  exit 1
}

echo " Download complete: $SERVER_ZIP"
echo ""

echo " Updating server files from ZIP..."
unzip -o "$SERVER_ZIP" || {
  echo " Failed to unzip server package."
  exit 1
}

if [ -f "bedrock_server" ]; then
  chmod +x bedrock_server
  echo " Made bedrock_server executable"
fi

echo ""
echo " Updating run script..."
cd "$HOME"
rm -f run
wget -q https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/refs/heads/main/run
chmod +x run
echo " Run script updated"

cd "$HOME"

echo ""
echo "========================================="
echo "   Update Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "  • Version: $VERSION_NAME"
echo "  • Latest files extracted"
echo "  • Worlds backed up (if present)"
if [ "$VERSION_NAME" = "Preview/Beta" ]; then
  echo ""
  echo "  IMPORTANT for Preview/Beta:"
  echo "  • Players need Minecraft Preview client"
  echo "  • Some stable add-ons may not work"
  echo "  • Script API beta add-ons now supported"
fi
echo ""
echo "You can now start your server using:"
echo "  cd ~"
echo "  ./run"
echo ""
