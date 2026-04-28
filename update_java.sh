#!/bin/bash
#  github.com/debojitsantra/BedrockServerTermux

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

echo ""
echo -e "${GREEN}${BOLD}  Minecraft Java Server Updater${RESET}"
echo -e "${CYAN}  Termux | github.com/debojitsantra/BedrockServerTermux${RESET}"
echo ""


command -v curl >/dev/null 2>&1 || { info "Installing curl..."; pkg install -y curl; }
command -v jq   >/dev/null 2>&1 || { info "Installing jq...";   pkg install -y jq;   }
command -v wget >/dev/null 2>&1 || { info "Installing wget..."; pkg install -y wget; }


SERVERS=()
MAIN_SERVER="$HOME/server"

[[ -f "$MAIN_SERVER/server.jar" ]] && SERVERS+=("$MAIN_SERVER")
for d in "$HOME"/server_*/; do
    [[ -f "${d}server.jar" ]] && SERVERS+=("${d%/}")
done

if [[ ${#SERVERS[@]} -eq 0 ]]; then
    echo -e "${RED}[✗]${RESET} No installed servers found."
    echo -e "    Run ${CYAN}setup_java.sh${RESET} first to install a server."
    echo ""
    exit 1
fi


info "Fetching PaperMC version data..."
VERSIONS_JSON=$(curl -s -H "$UA" "$FILL_API")
if [[ -z "$VERSIONS_JSON" ]]; then
    error "Could not reach PaperMC API. Check your internet connection."
fi


echo ""
echo -e "${BOLD}  Installed servers:${RESET}"
echo ""

declare -A SERVER_CURRENT_VER
declare -A SERVER_CURRENT_BUILD
declare -A SERVER_LATEST_BUILD
declare -A SERVER_HAS_UPDATE

IDX=0
for s in "${SERVERS[@]}"; do
    IDX=$((IDX + 1))

    CUR_VER="unknown"
    CUR_BLD="unknown"
    [[ -f "$s/.mc_version" ]] && CUR_VER=$(cat "$s/.mc_version")
    [[ -f "$s/.build_num"  ]] && CUR_BLD=$(cat "$s/.build_num")

    SERVER_CURRENT_VER[$IDX]="$CUR_VER"
    SERVER_CURRENT_BUILD[$IDX]="$CUR_BLD"


    LATEST_BLD="unknown"
    UPDATE_AVAILABLE=false

    if [[ "$CUR_VER" != "unknown" ]]; then
        BUILDS=$(curl -s -H "$UA" "$FILL_API/versions/$CUR_VER/builds" 2>/dev/null)
        if [[ -n "$BUILDS" ]] && echo "$BUILDS" | jq empty 2>/dev/null; then
            LATEST_BLD=$(echo "$BUILDS" | jq -r 'map(select(.channel == "STABLE")) | .[0].id // "unknown"')
            if [[ "$LATEST_BLD" != "unknown" && "$LATEST_BLD" != "$CUR_BLD" ]]; then
                UPDATE_AVAILABLE=true
            fi
        fi
    fi

    SERVER_LATEST_BUILD[$IDX]="$LATEST_BLD"
    SERVER_HAS_UPDATE[$IDX]="$UPDATE_AVAILABLE"

    
    if [[ "$UPDATE_AVAILABLE" == true ]]; then
        echo -e "  ${BOLD}$IDX)${RESET} ${CYAN}$s${RESET}"
        echo -e "     Version: ${BOLD}$CUR_VER${RESET}  |  Build: ${YELLOW}$CUR_BLD${RESET}  →  ${GREEN}$LATEST_BLD available${RESET} ${YELLOW}[UPDATE AVAILABLE]${RESET}"
    else
        echo -e "  ${BOLD}$IDX)${RESET} ${CYAN}$s${RESET}"
        echo -e "     Version: ${BOLD}$CUR_VER${RESET}  |  Build: ${GREEN}$CUR_BLD${RESET}  ${GREEN}[up to date]${RESET}"
    fi
    echo ""
done

TOTAL=$IDX


echo -e "${BOLD}  Which server do you want to update?${RESET}"
echo "  Enter a number from the list above, or:"
echo "    a) Update ALL servers that have updates available"
echo "    q) Quit"
echo ""
read -rp "  Choice: " SEL

[[ "$SEL" =~ ^[Qq]$ ]] && { echo "Cancelled."; exit 0; }


TARGETS=()
if [[ "$SEL" =~ ^[Aa]$ ]]; then
    for i in $(seq 1 $TOTAL); do
        [[ "${SERVER_HAS_UPDATE[$i]}" == "true" ]] && TARGETS+=("$i")
    done
    if [[ ${#TARGETS[@]} -eq 0 ]]; then
        success "All servers are already up to date!"
        exit 0
    fi
elif [[ "$SEL" =~ ^[0-9]+$ ]] && [[ "$SEL" -ge 1 ]] && [[ "$SEL" -le "$TOTAL" ]]; then
    TARGETS+=("$SEL")
else
    error "Invalid selection."
fi


for IDX in "${TARGETS[@]}"; do
    TARGET_DIR="${SERVERS[$((IDX - 1))]}"
    CUR_VER="${SERVER_CURRENT_VER[$IDX]}"
    CUR_BLD="${SERVER_CURRENT_BUILD[$IDX]}"

    echo ""
    echo -e "${BOLD}  Updating: ${CYAN}$TARGET_DIR${RESET}"
    echo ""

    echo -e "${BOLD}  Update options:${RESET}"
    echo -e "  1) ${GREEN}Same version ($CUR_VER)${RESET} — update to a newer build"
    echo -e "  2) ${CYAN}Different version${RESET}         — switch to another Minecraft version"
    echo ""
    read -rp "  Choice [default: 1]: " UPDATE_TYPE
    UPDATE_TYPE="${UPDATE_TYPE:-1}"

    TARGET_VERSION="$CUR_VER"

    if [[ "$UPDATE_TYPE" == "2" ]]; then
        
        VERSIONS_RAW=$(echo "$VERSIONS_JSON" | jq -r '.versions | to_entries[].value[]' | grep -E '^1[.]' | grep -v 'rc\|pre')
        STABLE_VERSIONS=$(echo "$VERSIONS_RAW" | head -10)

        echo ""
        echo -e "${BOLD}  Available versions (latest 10 stable):${RESET}"
        echo "$STABLE_VERSIONS" | nl -w3 -s') '
        echo ""
        read -rp "  Pick number or type version [default: 1]: " VER_INPUT

        if [[ "$VER_INPUT" =~ ^[0-9]+$ ]] && [[ "$VER_INPUT" -ge 1 ]] && [[ "$VER_INPUT" -le 10 ]]; then
            TARGET_VERSION=$(echo "$STABLE_VERSIONS" | sed -n "${VER_INPUT}p")
        elif [[ -z "$VER_INPUT" ]]; then
            TARGET_VERSION=$(echo "$STABLE_VERSIONS" | head -1)
        else
            TARGET_VERSION="$VER_INPUT"
        fi
    fi

  
    info "Fetching builds for PaperMC $TARGET_VERSION..."
    BUILDS=$(curl -s -H "$UA" "$FILL_API/versions/$TARGET_VERSION/builds")

    if [[ -z "$BUILDS" ]] || ! echo "$BUILDS" | jq empty 2>/dev/null; then
        warn "Could not fetch builds for $TARGET_VERSION. Skipping this server."
        continue
    fi

    LATEST_STABLE_BUILD=$(echo "$BUILDS" | jq -r 'map(select(.channel == "STABLE")) | .[0].id')

    if [[ -z "$LATEST_STABLE_BUILD" || "$LATEST_STABLE_BUILD" == "null" ]]; then
        warn "No stable builds found for $TARGET_VERSION. Skipping."
        continue
    fi

   
    echo ""
    echo -e "${BOLD}  Which build?${RESET}"
    echo -e "  1) Latest stable  (build ${GREEN}$LATEST_STABLE_BUILD${RESET})"
    echo -e "  2) Enter a specific build number"
    echo ""
    read -rp "  Choice [default: 1]: " BUILD_CHOICE
    BUILD_CHOICE="${BUILD_CHOICE:-1}"

    TARGET_BUILD="$LATEST_STABLE_BUILD"
    PAPER_URL=$(echo "$BUILDS" | jq -r 'map(select(.channel == "STABLE")) | .[0].downloads."server:default".url')

    if [[ "$BUILD_CHOICE" == "2" ]]; then
        echo ""
        echo -e "  Recent stable builds:"
        echo "$BUILDS" | jq -r 'map(select(.channel == "STABLE")) | .[].id | "  \(.)"' | head -10
        echo ""
        read -rp "  Enter build number: " CUSTOM_BUILD
        CUSTOM_URL=$(echo "$BUILDS" | jq -r --argjson b "$CUSTOM_BUILD" \
            '.[] | select(.id == $b) | .downloads."server:default".url')
        if [[ -z "$CUSTOM_URL" || "$CUSTOM_URL" == "null" ]]; then
            warn "Build $CUSTOM_BUILD not found. Falling back to latest stable."
        else
            TARGET_BUILD="$CUSTOM_BUILD"
            PAPER_URL="$CUSTOM_URL"
        fi
    fi

    [[ -z "$PAPER_URL" || "$PAPER_URL" == "null" ]] && { warn "Could not resolve download URL. Skipping."; continue; }

  
    if [[ "$TARGET_VERSION" == "$CUR_VER" && "$TARGET_BUILD" == "$CUR_BLD" ]]; then
        success "Already on $TARGET_VERSION build $TARGET_BUILD. Nothing to do."
        continue
    fi

    
    echo ""
    echo -e "  ${BOLD}Update summary:${RESET}"
    echo -e "    Server:   ${CYAN}$TARGET_DIR${RESET}"
    echo -e "    From:     PaperMC ${YELLOW}$CUR_VER${RESET} build ${YELLOW}$CUR_BLD${RESET}"
    echo -e "    To:       PaperMC ${GREEN}$TARGET_VERSION${RESET} build ${GREEN}$TARGET_BUILD${RESET}"
    echo ""
    read -rp "  Apply this update? (Y/n): " APPLY
    [[ "$APPLY" =~ ^[Nn]$ ]] && { warn "Skipped."; continue; }


    echo ""
    echo -e "${BOLD}  Backup options:${RESET}"
    echo "  1) Backup server.jar only"
    echo "  2) Backup entire server folder"
    echo "  3) Skip backup"
    echo ""
    read -rp "  Choice [default: 1]: " BACKUP_CHOICE
    BACKUP_CHOICE="${BACKUP_CHOICE:-1}"

    case "$BACKUP_CHOICE" in
        2)
            BACKUP="$HOME/server_backup_${CUR_VER}_b${CUR_BLD}_$(date +%Y%m%d%H%M%S).tar.gz"
            info "Backing up entire server folder → $(basename "$BACKUP")"
            tar -czf "$BACKUP" -C "$(dirname "$TARGET_DIR")" "$(basename "$TARGET_DIR")" \
                || warn "Full backup failed, continuing anyway."
            success "Full backup saved: $BACKUP"
            ;;
        3)
            warn "Skipping backup."
            ;;
        *)
            BACKUP="$TARGET_DIR/server_backup_${CUR_VER}_b${CUR_BLD}.jar"
            info "Backing up current server.jar → $(basename "$BACKUP")"
            cp "$TARGET_DIR/server.jar" "$BACKUP" || warn "Backup failed, continuing anyway."
            ;;
    esac
    
    info "Downloading PaperMC $TARGET_VERSION (build $TARGET_BUILD)..."
    wget -q --show-progress "$PAPER_URL" -O "$TARGET_DIR/server.jar" || {
        warn "Download failed. Restoring backup..."
        cp "$BACKUP" "$TARGET_DIR/server.jar"
        continue
    }

    echo "$TARGET_VERSION" > "$TARGET_DIR/.mc_version"
    echo "$TARGET_BUILD"   > "$TARGET_DIR/.build_num"

    success "Updated $TARGET_DIR -> PaperMC $TARGET_VERSION build $TARGET_BUILD"
done


echo ""

echo -e "${GREEN}${BOLD}   Update complete!${RESET}"

echo ""
echo -e "  Old server.jar files are backed up in each server folder."
echo -e "  You can delete them once you've confirmed the update works."
echo ""
echo -e "  ${BOLD}Start your server:${RESET}"
echo -e "    Main server:        ${CYAN}~/run${RESET}"
echo -e "    Versioned servers:  ${CYAN}~/run_<version>${RESET}"
echo ""
