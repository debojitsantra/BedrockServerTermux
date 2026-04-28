#!/bin/bash

# ─────────────────────────────────────────────────────────────
#  github.com/debojitsantra/BedrockServerTermux
# ─────────────────────────────────────────────────────────────

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

UA="User-Agent: BedrockServerTermux/1.0 (github.com/debojitsantra/BedrockServerTermux)"
FILL_API="https://fill.papermc.io/v3/projects/paper"

INSTALL_GEYSER=false
INSTALL_PLAYIT=false
SERVER_DIR="$HOME/server"

echo ""
echo -e "${GREEN}${BOLD}  Minecraft Java Server Setup${RESET}"
echo ""

info "Updating Termux packages..."
pkg update -y && pkg upgrade -y || error "Failed to update packages."
success "Packages updated."

info "Installing tur-repo..."
pkg install -y tur-repo || warn "TUR repo install failed, continuing..."
pkg update -y
success "TUR repo ready."


info "Installing Java 21, wget, curl, jq..."
pkg install -y openjdk-21 wget curl jq || error "Failed to install dependencies."
success "Dependencies installed."


echo ""
info "Fetching available PaperMC versions..."

VERSIONS_JSON=$(curl -s -H "$UA" "$FILL_API")
if [[ -z "$VERSIONS_JSON" ]]; then
    error "Could not fetch PaperMC versions. Check your internet connection."
fi

VERSIONS_RAW=$(echo "$VERSIONS_JSON" | jq -r '.versions | to_entries[].value[]' | grep -E '^1[.]' | grep -v 'rc\|pre')
LATEST=$(echo "$VERSIONS_RAW" | head -1)
STABLE_VERSIONS=$(echo "$VERSIONS_RAW" | head -10)

echo ""
echo -e "${BOLD}  Available versions (latest 10 stable):${RESET}"
echo "$STABLE_VERSIONS" | nl -w3 -s') '
echo ""
read -rp "  Pick number or type version [default: 1]: " VERSION_INPUT
if [[ "$VERSION_INPUT" =~ ^[0-9]+$ ]] && [[ "$VERSION_INPUT" -ge 1 ]] && [[ "$VERSION_INPUT" -le 10 ]]; then
    MC_VERSION=$(echo "$STABLE_VERSIONS" | sed -n "${VERSION_INPUT}p")
elif [[ -z "$VERSION_INPUT" ]]; then
    MC_VERSION="$LATEST"
else
    MC_VERSION="$VERSION_INPUT"
fi


echo ""
echo -e "${BOLD}  Which build do you want?${RESET}"
echo "  1) Latest stable (recommended)"
echo "  2) Enter a specific build number"
echo ""
read -rp "  Choice [default: 1]: " BUILD_CHOICE
BUILD_CHOICE="${BUILD_CHOICE:-1}"

info "Fetching builds for PaperMC $MC_VERSION..."
BUILDS=$(curl -s -H "$UA" "$FILL_API/versions/$MC_VERSION/builds")

if [[ -z "$BUILDS" ]] || ! echo "$BUILDS" | jq empty 2>/dev/null; then
    error "Could not fetch builds for $MC_VERSION. Version may not exist."
fi

case "$BUILD_CHOICE" in
    2)
        echo ""
        echo -e "  Recent stable builds:"
        echo "$BUILDS" | jq -r 'map(select(.channel == "STABLE")) | .[].id | "  \(.)"' | head -10
        echo ""
        read -rp "  Enter build number: " CUSTOM_BUILD
        PAPER_URL=$(echo "$BUILDS" | jq -r --argjson b "$CUSTOM_BUILD" \
            '.[] | select(.id == $b) | .downloads."server:default".url')
        BUILD_NUM="$CUSTOM_BUILD"
        if [[ -z "$PAPER_URL" || "$PAPER_URL" == "null" ]]; then
            warn "Build $CUSTOM_BUILD not found. Falling back to latest stable."
            BUILD_NUM=$(echo "$BUILDS" | jq -r 'map(select(.channel == "STABLE")) | .[0].id')
            PAPER_URL=$(echo "$BUILDS" | jq -r 'map(select(.channel == "STABLE")) | .[0].downloads."server:default".url')
        fi
        ;;
    *)
        BUILD_NUM=$(echo "$BUILDS" | jq -r 'map(select(.channel == "STABLE")) | .[0].id')
        PAPER_URL=$(echo "$BUILDS" | jq -r 'map(select(.channel == "STABLE")) | .[0].downloads."server:default".url')
        if [[ -z "$BUILD_NUM" || "$BUILD_NUM" == "null" ]]; then
            error "No stable build found for $MC_VERSION. Please choose a different version."
        fi
        ;;
esac

[[ -z "$BUILD_NUM" || "$BUILD_NUM" == "null" ]] && error "Could not resolve build number."
[[ -z "$PAPER_URL" || "$PAPER_URL" == "null" ]] && error "Could not resolve download URL."

success "Selected: PaperMC $MC_VERSION build $BUILD_NUM"


echo ""
echo -e "${BOLD}  Install Geyser?${RESET}"
echo -e "  Allows Bedrock/PE clients to join your Java server (port 19132)"
read -rp "  Install Geyser? (y/N): " GEYSER_INPUT
[[ "$GEYSER_INPUT" =~ ^[Yy]$ ]] && INSTALL_GEYSER=true


echo ""
echo -e "${BOLD}  Install Playit.gg?${RESET}"
echo -e "  Creates a free public tunnel so friends can join without port forwarding"
read -rp "  Install Playit? (y/N): " PLAYIT_INPUT
[[ "$PLAYIT_INPUT" =~ ^[Yy]$ ]] && INSTALL_PLAYIT=true


echo ""
echo -e "${BOLD}  Installing:${RESET}"
echo -e "  • PaperMC $MC_VERSION (build $BUILD_NUM)"
$INSTALL_GEYSER && echo -e "  • Geyser (Bedrock support)"
$INSTALL_PLAYIT && echo -e "  • Playit.gg (public tunnel)"
echo ""
read -rp "  Continue? (Y/n): " CONFIRM
[[ "$CONFIRM" =~ ^[Nn]$ ]] && { echo "Aborted."; exit 0; }

# Check existing servers
MAIN_SERVER="$HOME/server"
SERVER_DIR="$MAIN_SERVER"

# Collect all existing server directories
EXISTING_SERVERS=()
[[ -f "$MAIN_SERVER/server.jar" ]] && EXISTING_SERVERS+=("$MAIN_SERVER")
for d in "$HOME"/server_*/; do
    [[ -f "${d}server.jar" ]] && EXISTING_SERVERS+=("${d%/}")
done

if [[ ${#EXISTING_SERVERS[@]} -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}[!]${RESET} Existing server(s) found:"
    echo ""
    for s in "${EXISTING_SERVERS[@]}"; do
        VER="unknown"
        BLD="unknown"
        [[ -f "$s/.mc_version" ]] && VER=$(cat "$s/.mc_version")
        [[ -f "$s/.build_num"  ]] && BLD=$(cat "$s/.build_num")
        echo -e "  ${CYAN}$s${RESET}  →  PaperMC $VER (build $BLD)"
    done
    echo ""
    echo -e "${BOLD}  What do you want to do?${RESET}"
    echo "  1) Install as a separate server  →  folder: server_${MC_VERSION}  (keeps existing server intact)"
    echo "  2) Overwrite the main server     →  folder: server              (replaces it with this version)"
    echo ""
    read -rp "  Choice [default: 1]: " EXIST_CHOICE
    EXIST_CHOICE="${EXIST_CHOICE:-1}"

    if [[ "$EXIST_CHOICE" == "2" ]]; then
        warn "Overwriting existing server at $MAIN_SERVER..."
        SERVER_DIR="$MAIN_SERVER"
    else
        SERVER_DIR="$HOME/server_${MC_VERSION}"
        success "Installing as separate server at: $SERVER_DIR"
    fi
fi


mkdir -p "$SERVER_DIR/plugins" || error "Failed to create server directory."
success "Server directory ready: $SERVER_DIR"

echo "$MC_VERSION" > "$SERVER_DIR/.mc_version"
echo "$BUILD_NUM"  > "$SERVER_DIR/.build_num"


info "Downloading PaperMC $MC_VERSION (build $BUILD_NUM)..."
wget -q --show-progress "$PAPER_URL" -O "$SERVER_DIR/server.jar" || error "Failed to download PaperMC."
success "PaperMC downloaded."


echo "eula=true" > "$SERVER_DIR/eula.txt"
success "EULA accepted."

if $INSTALL_GEYSER; then
    info "Downloading Geyser..."
    wget -q --show-progress \
        "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot" \
        -O "$SERVER_DIR/plugins/Geyser-Spigot.jar" || error "Failed to download Geyser."
    success "Geyser downloaded."
fi

if $INSTALL_PLAYIT; then
    info "Installing Playit.gg..."
    pkg install -y playit || warn "Playit install failed. Try manually: pkg install playit"
    success "Playit installed."
fi

if [[ "$SERVER_DIR" == "$MAIN_SERVER" ]]; then
    RUN_SCRIPT="$HOME/run"
else
    RUN_SCRIPT="$HOME/run_${MC_VERSION}"
fi

cat > "$SERVER_DIR/start.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
FILTER='JLineNativeLoader|libjlinenative|com\.sun\.jna|oshi\.|NoClassDefFoundError|ExceptionInInitializerError|UnsatisfiedLinkError|dlopen failed|libc\.so|libutil\.so|libdl\.so|MacAddressUtil|usable hardware|udev library|async-profiler|libasyncProfiler|Investigate incompatible|Did not find udev|Did not JNA|Failed retrieving info for group|^\s+at |Caused by:|jline\.nativ|WARNING: Failed to load native|NativeLong|NativeLibrar'
java -Xmx512M -Xms512M -Djna.nosys=true -Djline.terminal=jline.UnsupportedTerminal \
     -jar server.jar nogui 2>&1 | grep -Ev "$FILTER"
EOF
chmod +x "$SERVER_DIR/start.sh"
success "start.sh created."

cat > "$RUN_SCRIPT" << EOF
#!/bin/bash
cd "$SERVER_DIR" 2>/dev/null || { echo "Server folder not found."; exit 1; }
trap 'echo ""; echo "Server stopped."; exit 0' SIGINT
while true; do
    echo "Starting server..."
    bash start.sh
    EXIT_CODE=\$?
    [[ \$EXIT_CODE -eq 0 ]] && { echo "Server stopped."; break; }
    echo "Server crashed (exit code: \$EXIT_CODE). Restarting in 5s..."
    sleep 5
done
EOF
chmod +x "$RUN_SCRIPT"
success "Run script created: $RUN_SCRIPT"

info "Downloading update script..."
UPDATE_SCRIPT="$HOME/update_java.sh"
wget -q --show-progress \
    "https://raw.githubusercontent.com/debojitsantra/BedrockServerTermux/main/update_java.sh" \
    -O "$UPDATE_SCRIPT" || warn "Could not download update_java.sh. You can get it later from the GitHub repo."
chmod +x "$UPDATE_SCRIPT" 2>/dev/null
success "Update script saved to: $UPDATE_SCRIPT"


echo -e "${GREEN}${BOLD} Setup complete!${RESET}"
echo ""
echo -e "  ${BOLD}Server:${RESET}   PaperMC $MC_VERSION (build $BUILD_NUM)"
echo -e "  ${BOLD}Location:${RESET} $SERVER_DIR"
$INSTALL_GEYSER && echo -e "  ${BOLD}Geyser:${RESET}   Installed (Bedrock on port ${CYAN}19132${RESET})"
$INSTALL_PLAYIT && echo -e "  ${BOLD}Playit:${RESET}   Installed"
echo ""
echo -e "  ${CYAN}Session 1 — Start server:${RESET}"
echo -e "    ${CYAN}$RUN_SCRIPT${RESET}"
echo ""
if $INSTALL_PLAYIT; then
    echo -e "  ${CYAN}Session 2 — Start tunnel:${RESET}"
    echo -e "    ${CYAN}playit${RESET}"
    echo ""
fi
echo -e "  ${BOLD}Stop server:${RESET}  type ${CYAN}stop${RESET} in the server console"
echo -e "  ${BOLD}Update server:${RESET} run ${CYAN}~/update_java.sh${RESET}"
echo ""
echo -e "  ${BOLD}Java port:${RESET}    ${CYAN}25565${RESET}"
$INSTALL_GEYSER && echo -e "  ${BOLD}Bedrock port:${RESET} ${CYAN}19132${RESET}"
echo ""
