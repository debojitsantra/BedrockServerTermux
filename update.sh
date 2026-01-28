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

echo "Fetching latest Bedrock server download URL from Mojang..."

DOWNLOAD_URL="$(
  curl -s "$API_URL" \
  | jq -r '.result.links[] | select(.downloadType=="serverBedrockLinux") | .downloadUrl'
)"

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
  echo " Could not get latest Bedrock server download URL. API may have changed or is down."
  exit 1
fi

echo " Found latest server URL:"
echo "   $DOWNLOAD_URL"
echo

# backup
if [ -d "worlds" ]; then
  TS="$(date +%Y%m%d_%H%M%S)"
  BACKUP_FILE="worlds_backup_${TS}.tar.gz"
  echo " Backing up 'worlds' directory to $BACKUP_FILE ..."
  tar -czf "$BACKUP_FILE" worlds || {
    echo "Failed to create backup. Aborting to avoid data loss."
    exit 1
  }
  echo " Backup complete."
  echo
else
  echo "No 'worlds' directory found. Skipping world backup."
  echo
fi

# download
echo "Downloading latest Bedrock server..."
rm -f "$SERVER_ZIP"

wget -q --show-progress "$DOWNLOAD_URL" -O "$SERVER_ZIP" || {
  echo "Failed to download Bedrock server ZIP."
  exit 1
}

echo "Download complete: $SERVER_ZIP"
echo

echo "Updating server files from ZIP..."
unzip -o "$SERVER_ZIP" || {
  echo "Failed to unzip server package."
  exit 1
}


if [ -f "bedrock_server" ]; then
  chmod +x bedrock_server
fi


cd $HOME
rm run
wget https://github.com/debojitsantra/BedrockServerTermux/blob/main/run
chmod +x run
cd $HOME

echo
echo "Update complete!"
echo "   - Latest files extracted."
echo "   - Worlds backed up (if present)."
echo
echo "You can now start your server using your usual start script."
