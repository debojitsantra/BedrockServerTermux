#!/bin/bash

# ==============================================================================
# Minecraft Bedrock Dedicated Server Addon Installer
# ==============================================================================

set -euo pipefail

# ==============================================================================
# Functions
# ==============================================================================

log() { echo "[INFO] $1"; }
warn() { echo "[WARN] $1"; }
error() { echo "[ERROR] $1"; exit 1; }

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Install addons:
  $(basename "$0") -s <path> -w <name> -a <addon> [-a <addon> ...] [-d <dir>] [--create]

List/Remove installed addons:
  $(basename "$0") -s <path> -w <name> -l [--json]
  $(basename "$0") -s <path> -w <name> -r [<uuid> ...] [--purge]

Options:
  -s, --server <path>   Path to the Bedrock server root directory.
  -w, --world <name>    Name of the world (e.g., "MyWorld").
  -a, --addon <path>    Path to a .mcaddon, .mcpack, or .zip file (can be repeated).
  -d, --addon-dir <dir> Directory containing addon files (scanned recursively).
  -l, --list            List addons installed in the specified world.
  --json                With -l, output JSON instead of a table.
  -r, --remove [<uuid> ...] Remove one or more addons by UUID (space-separated). Can also be repeated. Without a UUID, enter interactive mode.
  --purge               With -r, also delete the pack files from resource_packs/ and behavior_packs/.
  -c, --create          Automatically create the world directory and update
                        server.properties if the world does not exist.
  -h, --help            Show this help message and exit.

Examples:
  $(basename "$0") -s /opt/bedrock -w MyWorld -a addon1.mcaddon -a addon2.mcpack --create
  $(basename "$0") -s /opt/bedrock -w MyWorld -d ./my_addons/ --create
  $(basename "$0") -s /opt/bedrock -w MyWorld -l
  $(basename "$0") -s /opt/bedrock -w MyWorld -l --json
EOF
}

strip_color() {
    # Remove Minecraft § color codes and reset
    sed 's/§[0-9a-fklmnor]//gI' <<< "$1"
}

INSTALLED_ENTRIES=()

collect_entries_array() {
    local json_file="$1"
    local pack_type="$2"
    local pack_dir="$3"
    local server_root="$4"

    if [ ! -f "$json_file" ]; then
        return
    fi

    local count
    count=$(jq -r 'length // 0' "$json_file" 2>/dev/null || echo "0")
    [ "$count" -eq 0 ] && return

    for i in $(seq 0 $((count - 1))); do
        local uuid version name
        uuid=$(jq -r ".[$i].pack_id // empty" "$json_file" 2>/dev/null || true)
        version=$(jq -c ".[$i].version // []" "$json_file" 2>/dev/null || echo "[]")
        name=""

        if [ -z "$uuid" ]; then
            name=$(jq -r ".[$i].name // \"\"" "$json_file" 2>/dev/null || true)
            INSTALLED_ENTRIES+=("$name|$uuid|$version|$pack_type")
            continue
        fi

        local manifest_file="$server_root/$pack_dir/$uuid/manifest.json"
        if [ -f "$manifest_file" ]; then
            name=$(jq -r '.header.name // "Unknown"' "$manifest_file" 2>/dev/null || echo "Unknown")
        else
            name="(missing: $uuid)"
        fi

        INSTALLED_ENTRIES+=("$name|$uuid|$version|$pack_type")
    done
}

list_addons() {
    local world_path="$1"
    local server_root="$2"
    local json_flag="$3"

    INSTALLED_ENTRIES=()
    collect_entries_array "$world_path/world_resource_packs.json" "RP" "resource_packs" "$server_root"
    collect_entries_array "$world_path/world_behavior_packs.json" "BP" "behavior_packs" "$server_root"

    if [ "${#INSTALLED_ENTRIES[@]}" -eq 0 ]; then
        echo "No addons found in world '$world_path'."
        return
    fi

    if [ "$json_flag" = true ]; then
        echo "["
        local first=true
        for entry in "${INSTALLED_ENTRIES[@]}"; do
            IFS='|' read -r name uuid version ptype <<< "$entry"
            if [ "$first" = true ]; then
                first=false
            else
                echo ","
            fi
            printf '{"name":"%s","uuid":"%s","version":%s,"type":"%s"}' "$(strip_color "$name")" "$uuid" "$version" "$ptype"
        done
        echo ""
        echo "]"
    else
        local name_w=36 uuid_w=36 version_w=12
        printf "%-${name_w}s %-${uuid_w}s %-${version_w}s %s\n" "NAME" "UUID" "VERSION" "TYPE"
        printf "%${name_w}s %${uuid_w}s %${version_w}s %s\n" | tr ' ' '-'
        for entry in "${INSTALLED_ENTRIES[@]}"; do
            IFS='|' read -r name uuid version ptype <<< "$entry"
            name=$(strip_color "$name")
            if [ ${#name} -gt $name_w ]; then
                name="${name:0:$((name_w-3))}..."
            fi
            printf "%-${name_w}s %-${uuid_w}s %-${version_w}s %s\n" "$name" "$uuid" "$version" "$ptype"
        done
    fi
}

remove_addon() {
    local world_path="$1"
    local server_root="$2"
    local uuid="$3"
    local purge="$4"

    local removed=false

    local rp_json="$world_path/world_resource_packs.json"
    if [ -f "$rp_json" ]; then
        local before after
        before=$(jq length "$rp_json" 2>/dev/null || echo "0")
        if [ "$before" -gt 0 ]; then
            local tmp="${rp_json}.tmp"
            jq "map(select(.pack_id != \"$uuid\"))" "$rp_json" > "$tmp" 2>/dev/null && mv "$tmp" "$rp_json"
            after=$(jq length "$rp_json" 2>/dev/null || echo "0")
            if [ "$after" -lt "$before" ]; then
                log "Removed from world_resource_packs.json"
                removed=true
            fi
        fi
    fi

    local bp_json="$world_path/world_behavior_packs.json"
    if [ -f "$bp_json" ]; then
        local before after
        before=$(jq length "$bp_json" 2>/dev/null || echo "0")
        if [ "$before" -gt 0 ]; then
            local tmp="${bp_json}.tmp"
            jq "map(select(.pack_id != \"$uuid\"))" "$bp_json" > "$tmp" 2>/dev/null && mv "$tmp" "$bp_json"
            after=$(jq length "$bp_json" 2>/dev/null || echo "0")
            if [ "$after" -lt "$before" ]; then
                log "Removed from world_behavior_packs.json"
                removed=true
            fi
        fi
    fi

    if [ "$purge" = true ]; then
        if [ -d "$server_root/resource_packs/$uuid" ]; then
            rm -rf "$server_root/resource_packs/$uuid"
            log "Deleted resource_packs/$uuid"
        fi
        if [ -d "$server_root/behavior_packs/$uuid" ]; then
            rm -rf "$server_root/behavior_packs/$uuid"
            log "Deleted behavior_packs/$uuid"
        fi
    fi

    if [ "$removed" = false ]; then
        warn "No entries found for UUID: $uuid in world pack registries."
    else
        log "Removal complete."
    fi
}

interactive_remove() {
    local world_path="$1"
    local server_root="$2"

    INSTALLED_ENTRIES=()
    collect_entries_array "$world_path/world_resource_packs.json" "RP" "resource_packs" "$server_root"
    collect_entries_array "$world_path/world_behavior_packs.json" "BP" "behavior_packs" "$server_root"

    if [ "${#INSTALLED_ENTRIES[@]}" -eq 0 ]; then
        echo "No addons found in this world."
        exit 1
    fi

    echo ""
    echo "Installed addons:"
    echo ""
    for i in "${!INSTALLED_ENTRIES[@]}"; do
        IFS='|' read -r name uuid version ptype <<< "${INSTALLED_ENTRIES[$i]}"
        name=$(strip_color "$name")
        printf "%3d. [%s] %-36s  %s\n" $((i+1)) "$ptype" "$uuid" "$name"
    done
    echo ""
    read -r -p "Enter number or UUID to remove (or q to cancel): " choice

    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        local idx=$((choice - 1))
        if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#INSTALLED_ENTRIES[@]}" ]; then
            IFS='|' read -r name uuid version ptype <<< "${INSTALLED_ENTRIES[$idx]}"
            echo ""
            log "Selected: $name ($uuid)"
            remove_addon "$world_path" "$server_root" "$uuid" "$PURGE_MODE"
        else
            error "Invalid selection: $choice"
        fi
    elif [[ "$choice" =~ ^[qQ]$ ]] || [ -z "$choice" ]; then
        echo "Cancelled."
        exit 0
    else
        echo ""
        remove_addon "$world_path" "$server_root" "$choice" "$PURGE_MODE"
    fi
}

# ==============================================================================
# Dependency Checks
# ==============================================================================

for cmd in jq unzip rsync; do
    command -v "$cmd" >/dev/null 2>&1 || {
        log "Installing missing dependency: $cmd"
        apt install -y "$cmd" || error "Failed to install $cmd."
    }
done

# ==============================================================================
# Parse Arguments
# ==============================================================================

SERVER_ROOT=""
WORLD_NAME=""
ADDON_PATHS=()
ADDON_DIRS=()
LIST_MODE=false
JSON_OUTPUT=false
AUTO_CREATE=false
REMOVE_MODE=false
REMOVE_UUIDS=()
PURGE_MODE=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--server) SERVER_ROOT="$2"; shift ;;
        -w|--world)  WORLD_NAME="$2"; shift ;;
        -a|--addon)  ADDON_PATHS+=("$2"); shift ;;
        -d|--addon-dir) ADDON_DIRS+=("$2"); shift ;;
        -l|--list)   LIST_MODE=true ;;
        --json)      JSON_OUTPUT=true ;;
        -r|--remove)
            REMOVE_MODE=true
            while [[ -n "${2-}" && "${2-}" != -* ]]; do
                REMOVE_UUIDS+=("$2")
                shift
            done
            ;;
        --purge)     PURGE_MODE=true ;;
        -c|--create) AUTO_CREATE=true ;;
        -h|--help)   show_help; exit 0 ;;
        *)           error "Unknown parameter passed: $1\nRun with --help for usage." ;;
    esac
    shift
done

# Validate required arguments
[ -z "$SERVER_ROOT" ] && error "Server root is required. Use -s or --server."
[ -z "$WORLD_NAME" ] && error "World name is required. Use -w or --world."

WORLD_PATH="$SERVER_ROOT/worlds/$WORLD_NAME"

# ==============================================================================
# Validate Paths & Bootstrap New Worlds
# ==============================================================================

[ -d "$SERVER_ROOT" ] || error "Server root does not exist: $SERVER_ROOT"

# ==============================================================================
# List Mode
# ==============================================================================

if [ "$LIST_MODE" = true ]; then
    [ -d "$WORLD_PATH" ] || error "World directory does not exist: $WORLD_PATH"
    list_addons "$WORLD_PATH" "$SERVER_ROOT" "$JSON_OUTPUT"
    exit 0
fi

# ==============================================================================
# Remove Mode
# ==============================================================================

if [ "$REMOVE_MODE" = true ]; then
    [ -d "$WORLD_PATH" ] || error "World directory does not exist: $WORLD_PATH"
    if [ "${#REMOVE_UUIDS[@]}" -gt 0 ]; then
        for uuid in "${REMOVE_UUIDS[@]}"; do
            remove_addon "$WORLD_PATH" "$SERVER_ROOT" "$uuid" "$PURGE_MODE"
        done
    else
        interactive_remove "$WORLD_PATH" "$SERVER_ROOT"
    fi
    exit 0
fi

# ==============================================================================
# Temporary Workspace
# ==============================================================================

TEMP_DIR=$(mktemp -d)
CLEAN_MANIFEST="$TEMP_DIR/clean_manifest.json"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# ==============================================================================
# Collect Addon Sources
# ==============================================================================

ADDON_SOURCES=()

for ap in "${ADDON_PATHS[@]}"; do
    [ -e "$ap" ] || error "Addon path does not exist: $ap"
    ADDON_SOURCES+=("$ap")
done

for ad in "${ADDON_DIRS[@]}"; do
    [ -d "$ad" ] || error "Addon directory does not exist: $ad"
    find "$ad" -type f \( -name "*.mcaddon" -o -name "*.mcpack" -o -name "*.zip" \) -print0 > "$TEMP_DIR/find_sources.tmp"
    while IFS= read -r -d '' f; do
        ADDON_SOURCES+=("$f")
    done < "$TEMP_DIR/find_sources.tmp"
done

[ "${#ADDON_SOURCES[@]}" -eq 0 ] && error "No addon paths or directories provided. Use -a or -d."

# ==============================================================================
# Bootstrap New Worlds
# ==============================================================================

if [ ! -d "$WORLD_PATH" ]; then
    if [ "$AUTO_CREATE" = true ]; then
        log "World directory does not exist. Auto-creating: $WORLD_PATH"
        mkdir -p "$WORLD_PATH"

        PROPS_FILE="$SERVER_ROOT/server.properties"
        if [ -f "$PROPS_FILE" ]; then
            sed "s/^[Ll]evel-[Nn]ame[[:space:]]*=.*/level-name=$WORLD_NAME/" "$PROPS_FILE" > "${PROPS_FILE}.tmp"

            if ! grep -qi "^level-name=" "${PROPS_FILE}.tmp"; then
                echo "level-name=$WORLD_NAME" >> "${PROPS_FILE}.tmp"
            fi

            mv "${PROPS_FILE}.tmp" "$PROPS_FILE"
            log "Updated server.properties: level-name=$WORLD_NAME"
        else
            warn "server.properties not found. Skipping config update."
        fi
    else
        error "World directory '$WORLD_NAME' does not exist. Use --create to initialize it automatically."
    fi
elif [ ! -f "$WORLD_PATH/level.dat" ]; then
    log "World folder exists but is not generated yet. Proceeding with pre-generation install."
fi

# ==============================================================================
# Ensure Pack Directories Exist
# ==============================================================================

mkdir -p "$SERVER_ROOT/resource_packs"
mkdir -p "$SERVER_ROOT/behavior_packs"

# ==============================================================================
# Extract Addon Sources
# ==============================================================================

log "Extracting addon files..."

for ADDON_SRC in "${ADDON_SOURCES[@]}"; do
    if [ -d "$ADDON_SRC" ]; then
        cp -R "$ADDON_SRC"/. "$TEMP_DIR/"
    elif [[ "$ADDON_SRC" == *.mcaddon || "$ADDON_SRC" == *.mcpack || "$ADDON_SRC" == *.zip ]]; then
        unzip -qo "$ADDON_SRC" -d "$TEMP_DIR"
    else
        warn "Unsupported format, skipping: $ADDON_SRC"
    fi
done

# Extract nested .mcpack files
find "$TEMP_DIR" -type f -name "*.mcpack" -print0 > "$TEMP_DIR/subpacks.tmp"
while IFS= read -r -d '' subpack; do
    subpack_dir="${subpack%.mcpack}"
    mkdir -p "$subpack_dir"
    unzip -qo "$subpack" -d "$subpack_dir"
    rm -f "$subpack"
done < "$TEMP_DIR/subpacks.tmp"

# ==============================================================================
# Find & Process Manifests
# ==============================================================================

MANIFEST_COUNT=0

find "$TEMP_DIR" -type f -name "manifest.json" -print0 > "$TEMP_DIR/manifests.tmp"
while IFS= read -r -d '' manifest; do
    MANIFEST_COUNT=$((MANIFEST_COUNT + 1))
    PACK_DIR=$(dirname "$manifest")

    sed '/^[[:space:]]*\/\//d' "$manifest" > "$CLEAN_MANIFEST"

    UUID=$(jq -r '.header.uuid // empty' "$CLEAN_MANIFEST" 2>/dev/null || true)
    NAME=$(jq -r '.header.name // "Unknown Pack"' "$CLEAN_MANIFEST" 2>/dev/null || true)

    VERSION=$(jq -c '.header.version // [1,0,0]' "$CLEAN_MANIFEST" 2>/dev/null || echo "[1,0,0]")
    if ! echo "$VERSION" | jq -e 'type=="array"' >/dev/null 2>&1; then
        VERSION="[1,0,0]"
    fi

    if [ -z "$UUID" ]; then
        continue
    fi

    echo "--------------------------------------------------"
    echo "Installing : $NAME"
    echo "UUID       : $UUID"
    echo "--------------------------------------------------"

    INSTALL_RP=false
    INSTALL_BP=false

    MODULE_TYPES=$(jq -r '.modules[].type // empty' "$CLEAN_MANIFEST" 2>/dev/null | sort -u || true)

    while IFS= read -r MODULE_TYPE; do
        case "$MODULE_TYPE" in
            resources|client_data) INSTALL_RP=true ;;
            data) INSTALL_BP=true ;;
        esac
    done <<< "$MODULE_TYPES"

    CATEGORIES=()
    $INSTALL_RP && CATEGORIES+=("resource_packs:world_resource_packs.json")
    $INSTALL_BP && CATEGORIES+=("behavior_packs:world_behavior_packs.json")

    for CAT in "${CATEGORIES[@]}"; do
        IFS=":" read -r CATEGORY_DIR JSON_FILE <<< "$CAT"

        TARGET_DIR="$SERVER_ROOT/$CATEGORY_DIR/$UUID"
        TARGET_JSON="$WORLD_PATH/$JSON_FILE"

        if [ -d "$TARGET_DIR" ]; then
            log "Already installed globally. Skipping copy."
        else
            mkdir -p "$TARGET_DIR"
            rsync -a --exclude=".*" --exclude="*.mcpack" --exclude="*.mcaddon" --exclude="*.zip" "$PACK_DIR/" "$TARGET_DIR/"
            log "Copied to $CATEGORY_DIR/"
        fi

        if [ ! -s "$TARGET_JSON" ] || ! jq empty "$TARGET_JSON" >/dev/null 2>&1; then
            echo "[]" > "$TARGET_JSON"
        fi

        EXISTS=$(jq -r "map(select(.pack_id == \"$UUID\")) | length" "$TARGET_JSON" 2>/dev/null || echo "0")

        if [ "$EXISTS" -eq 0 ]; then
            TMP_JSON="$TARGET_JSON.tmp"
            jq ". += [{ \"pack_id\": \"$UUID\", \"version\": $VERSION }]" "$TARGET_JSON" > "$TMP_JSON"
            mv "$TMP_JSON" "$TARGET_JSON"
            log "Registered in $JSON_FILE"
        else
            warn "Pack '$NAME' is already registered in $JSON_FILE. Skipping registration."
        fi
    done

done < "$TEMP_DIR/manifests.tmp"

if [ "$MANIFEST_COUNT" -eq 0 ]; then
    error "No manifest.json files found. This is probably not a valid Bedrock addon."
fi

echo
log "Installation complete. Server is ready to start."
