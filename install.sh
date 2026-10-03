#!/bin/sh
set -eu

RAW_BASE="https://github.com/Jackson4Rocks/miniland"
RAW_BASE_URL="https://raw.githubusercontent.com/Jackson4Rocks/miniland/main"

BIN_DIR="$HOME/.local/bin"
XDG_BIN_HOME_VALUE="$(printenv XDG_BIN_HOME 2>/dev/null || true)"
[ -n "$XDG_BIN_HOME_VALUE" ] && BIN_DIR="$XDG_BIN_HOME_VALUE"

HYPR_DIR="$HOME/.config/hypr"
HYPR_CONF="$HYPR_DIR/hyprland.conf"
HYPR_CONFIG_VALUE="$(printenv HYPRLAND_CONFIG 2>/dev/null || true)"
[ -n "$HYPR_CONFIG_VALUE" ] && HYPR_CONF="$HYPR_CONFIG_VALUE"

MINILAND_CONF="$HYPR_DIR/miniland.conf"
MINILAND_LUA="$HYPR_DIR/miniland.lua"
INSTALL_BIN="$BIN_DIR/miniland"
TTY="/dev/tty"

say() {
    printf '%s %s\n' '==>' "$*"
}

warn() {
    printf '%s %s\n' 'warning:' "$*" >&2
}

die() {
    printf '%s %s\n' 'error:' "$*" >&2
    exit 1
}

[ -r "$TTY" ] || die "an interactive terminal is required for keybind setup"
command -v jq >/dev/null 2>&1 || die "jq is required. Install jq and run this installer again."

read_tty() {
    IFS= read -r "$@" < "$TTY"
}

prompt() {
    printf '%s' "$*" > "$TTY"
}

normalize() {
    token="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"

    case "$token" in
        CONTROL) echo CTRL ;;
        CTRL) echo CTRL ;;
        META|WINDOWS|WIN|GUI|MOD4) echo SUPER ;;
        ESC|ESCAPE) echo ESCAPE ;;
        ENTER) echo RETURN ;;
        DELETE|DEL) echo DELETE ;;
        *) echo "$token" ;;
    esac
}

parse_bind() {
    raw="$1"

    oldifs="$IFS"
    IFS='+'
    set -- $raw
    IFS="$oldifs"

    [ "$#" -ge 1 ] || return 1

    key=""
    mods=""
    i=1

    for part in "$@"; do
        part="$(printf '%s' "$part" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [ -n "$part" ] || return 1

        token="$(normalize "$part")"

        if [ "$i" -eq "$#" ]; then
            key="$token"
        else
            case "$token" in
                SUPER|SHIFT|CTRL|ALT|ALTGR|CAPSLOCK|HYPER)
                    if [ -n "$mods" ]; then
                        mods="$mods $token"
                    else
                        mods="$token"
                    fi
                    ;;
                *) return 1 ;;
            esac
        fi

        i=$((i + 1))
    done

    [ -n "$key" ] || return 1
    printf '%s|%s\n' "$mods" "$key"
}

format_bind() {
    mods="$(printf '%s' "$1" | cut -d'|' -f1)"
    key="$(printf '%s' "$1" | cut -d'|' -f2)"

    if [ -n "$mods" ]; then
        printf '%s + %s' "$(printf '%s' "$mods" | sed 's/ / + /g')" "$key"
    else
        printf '%s' "$key"
    fi
}

ask_bind() {
    label="$1"
    default="$2"

    while :; do
        prompt "$label [$(format_bind "$default")]: "
        read_tty answer || answer=""

        if [ -z "$answer" ]; then
            printf '%s\n' "$default"
            return 0
        fi

        parsed="$(parse_bind "$answer" 2>/dev/null || true)"

        if [ -n "$parsed" ]; then
            printf '%s\n' "$parsed"
            return 0
        fi

        warn "Invalid keybind. Example: SUPER + M or SUPER + SHIFT + N"
    done
}

detect_hypr_mode() {
    HYPR_MODE="legacy"

    case "$HYPR_CONF" in
        *.lua)
            HYPR_MODE="lua"
            return 0
            ;;
    esac

    if command -v hyprctl >/dev/null 2>&1; then
        version_line="$(hyprctl version 2>/dev/null | sed -n '1p' || true)"
        version_numbers="$(printf '%s\n' "$version_line" |
            sed -n 's/^Hyprland[[:space:]]\+\([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2/p')"

        if [ -n "$version_numbers" ]; then
            set -- $version_numbers
            major="$1"
            minor="$2"

            if [ "$major" -gt 0 ] ||
               [ "$major" -eq 0 ] && [ "$minor" -ge 55 ]; then
                HYPR_MODE="lua"
                return 0
            fi
        fi
    fi

    if [ -z "$HYPR_CONFIG_VALUE" ] &&
       [ ! -f "$HYPR_DIR/hyprland.conf" ] &&
       [ -f "$HYPR_DIR/hyprland.lua" ]; then
        HYPR_CONF="$HYPR_DIR/hyprland.lua"
        HYPR_MODE="lua"
    fi
}

detect_hypr_mode

config_for_existing() {
    if [ "$HYPR_MODE" = "lua" ]; then
        printf '%s\n' "$MINILAND_LUA"
    else
        printf '%s\n' "$MINILAND_CONF"
    fi
}

extract_bind() {
    action="$1"
    file="$(config_for_existing)"

    [ -f "$file" ] || return 1

    if [ "$HYPR_MODE" = "lua" ]; then
        line="$(grep -F "miniland $action" "$file" 2>/dev/null | tail -n 1 || true)"
        [ -n "$line" ] || return 1

        combo="$(printf '%s' "$line" | sed -n 's/.*hl\.bind("\([^"]*\)".*/\1/p')"
        [ -n "$combo" ] || return 1

        parse_bind "$combo"
        return 0
    fi

    line="$(grep -E '^[[:space:]]*bind[a-z]*[[:space:]]*=' "$file" 2>/dev/null |
        grep -F "miniland $action" |
        tail -n 1 || true)"

    [ -n "$line" ] || return 1

    mods="$(printf '%s' "$line" |
        cut -d',' -f1 |
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    key="$(printf '%s' "$line" |
        cut -d',' -f2 |
        sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    [ -n "$key" ] || return 1

    mods="$(printf '%s' "$mods" | tr '_' ' ')"
    printf '%s|%s\n' "$mods" "$key"
}

legacy_binding_line() {
    parsed="$1"
    command="$2"

    mods="$(printf '%s' "$parsed" | cut -d'|' -f1 | tr ' ' '_')"
    key="$(printf '%s' "$parsed" | cut -d'|' -f2)"

    if [ -n "$mods" ]; then
        printf 'bind = %s, %s, exec, %s %s\n' "$mods" "$key" "$INSTALL_BIN" "$command"
    else
        printf 'bind = , %s, exec, %s %s\n' "$key" "$INSTALL_BIN" "$command"
    fi
}

lua_binding_line() {
    parsed="$1"
    command="$2"
    description="$3"

    mods="$(printf '%s' "$parsed" | cut -d'|' -f1)"
    key="$(printf '%s' "$parsed" | cut -d'|' -f2)"

    if [ -n "$mods" ]; then
        combo="$(printf '%s + %s' "$(printf '%s' "$mods" | sed 's/ / + /g')" "$key")"
    else
        combo="$key"
    fi

    printf 'hl.bind("%s", hl.dsp.exec_cmd("%s %s"), { description = "%s" })\n'         "$combo" "$INSTALL_BIN" "$command" "$description"
}

write_miniland_config() {
    if [ "$HYPR_MODE" = "lua" ]; then
        cat > "$MINILAND_LUA" <<EOF
-- Miniland keybindings
-- Generated by install.sh

$(lua_binding_line "$minimize_bind" minimize "Minimize focused window")
$(lua_binding_line "$picker_bind" picker "Open Miniland picker")
$(lua_binding_line "$shelf_bind" toggle-shelf "Show or hide Miniland shelf")
EOF
    else
        cat > "$MINILAND_CONF" <<EOF
# Miniland keybindings
# Generated by install.sh

$(legacy_binding_line "$minimize_bind" minimize)
$(legacy_binding_line "$picker_bind" picker)
$(legacy_binding_line "$shelf_bind" toggle-shelf)
EOF
    fi
}

cleanup_legacy_lua_sources() {
    [ "$HYPR_MODE" = "lua" ] || return 0
    [ -f "$HYPR_CONF" ] || return 0

    tmp="$HYPR_CONF.miniland.tmp"
    sed -E '/^[[:space:]]*source[[:space:]]*=.*miniland\.conf[[:space:]]*$/d'         "$HYPR_CONF" > "$tmp"

    if cmp -s "$HYPR_CONF" "$tmp"; then
        rm -f "$tmp"
        return 0
    fi

    mv "$tmp" "$HYPR_CONF"
    say "Removed old Miniland legacy source lines from $HYPR_CONF"
}

ensure_lua_require() {
    if [ -f "$HYPR_CONF" ]; then
        if grep -Eq '^[[:space:]]*require[[:space:]]*\([[:space:]]*["'"']miniland["'"'][[:space:]]*\)[[:space:]]*$' "$HYPR_CONF"; then
            say "Miniland is already required by Hyprland."
        else
            printf '\n-- Miniland\nrequire("miniland")\n' >> "$HYPR_CONF"
            say "Added Miniland require to $HYPR_CONF"
        fi
    else
        cat > "$HYPR_CONF" <<EOF
-- Hyprland Lua configuration
require("miniland")
EOF
        warn "Hyprland Lua config was not found, so $HYPR_CONF was created."
    fi
}

ensure_legacy_source() {
    if [ -f "$HYPR_CONF" ]; then
        if grep -Eq '^[[:space:]]*source[[:space:]]*=[[:space:]]*("?'"'"')?'$(printf '%s' "$MINILAND_CONF" | sed 's/[.[\*^$()+?{|]/\\&/g')'[[:space:]]*("?'"'"')?$' "$HYPR_CONF"; then
            say "Miniland is already sourced by Hyprland."
        else
            printf '\n# Miniland\nsource = %s\n' "$MINILAND_CONF" >> "$HYPR_CONF"
            say "Added Miniland to $HYPR_CONF"
        fi
    else
        cat > "$HYPR_CONF" <<EOF
# Hyprland configuration
source = $MINILAND_CONF
EOF
        warn "Hyprland config was not found, so $HYPR_CONF was created."
    fi
}

download_miniland() {
    if [ -f "./miniland" ]; then
        cat ./miniland
        return
    fi

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$RAW_BASE_URL/miniland"
        return
    fi

    if command -v wget >/dev/null 2>&1; then
        wget -qO- "$RAW_BASE_URL/miniland"
        return
    fi

    die "curl or wget is required to download Miniland."
}

say "Welcome to Miniland."
printf '%s\n' "This guided installer installs Miniland for your user account."
printf '%s\n' "Detected Hyprland config mode: $HYPR_MODE"
if [ "$HYPR_MODE" = "lua" ] && [ "$HYPR_CONF" != "$HYPR_DIR/hyprland.lua" ]; then
    printf '%s\n' "Using Lua parser with config file: $HYPR_CONF"
fi
printf '%s\n\n' "No root access is required."

minimize_bind="SUPER|M"
picker_bind="SUPER SHIFT|N"
shelf_bind="SUPER ALT|M"
keep=0
choice="C"

EXISTING_CONFIG="$(config_for_existing)"

if [ -f "$EXISTING_CONFIG" ]; then
    old_minimize="$(extract_bind minimize || true)"
    old_picker="$(extract_bind picker || true)"
    old_shelf="$(extract_bind toggle-shelf || true)"

    [ -n "$old_minimize" ] || old_minimize="$minimize_bind"
    [ -n "$old_picker" ] || old_picker="$picker_bind"
    [ -n "$old_shelf" ] || old_shelf="$shelf_bind"

    say "Existing Miniland configuration found."
    prompt "Use recommended defaults (picker = SUPER + SHIFT + N), keep current, or customize? [D/k/c]: "
    read_tty choice || choice="D"

    case "$(printf '%s' "$choice" | tr '[:lower:]' '[:upper:]')" in
        D|"")
            minimize_bind="SUPER|M"
            picker_bind="SUPER SHIFT|N"
            shelf_bind="SUPER ALT|M"
            keep=0
            choice="D"
            ;;
        K)
            minimize_bind="$old_minimize"
            picker_bind="$old_picker"
            shelf_bind="$old_shelf"
            keep=1
            ;;
        C)
            minimize_bind="SUPER|M"
            picker_bind="SUPER SHIFT|N"
            shelf_bind="SUPER ALT|M"
            keep=0
            choice="C"
            ;;
        *)
            die "unknown choice; use D, K, or C"
            ;;
    esac
fi

if [ "$keep" -eq 0 ] && [ "$choice" = "C" ]; then
    printf '\n%s\n' "Keybind setup"
    printf '%s\n' "Enter combinations like: SUPER + M"
    printf '%s\n\n' "Press Enter to accept the shown default."

    minimize_bind="$(ask_bind "Minimize focused window" "$minimize_bind")"
    picker_bind="$(ask_bind "Open Miniland picker" "$picker_bind")"
    shelf_bind="$(ask_bind "Show/hide Miniland shelf" "$shelf_bind")"

    if [ "$minimize_bind" = "$picker_bind" ] ||
       [ "$minimize_bind" = "$shelf_bind" ] ||
       [ "$picker_bind" = "$shelf_bind" ]; then
        die "two Miniland actions use the same keybind; please choose different keybinds"
    fi

    printf '\n%s\n' "Selected bindings:"
    printf '  %-8s %s\n' "Minimize" "$(format_bind "$minimize_bind")"
    printf '  %-8s %s\n' "Picker" "$(format_bind "$picker_bind")"
    printf '  %-8s %s\n' "Shelf" "$(format_bind "$shelf_bind")"

    prompt "Apply these bindings? [Y/change/cancel]: "
    read_tty confirm || confirm="Y"

    case "$(printf '%s' "$confirm" | tr '[:lower:]' '[:upper:]')" in
        Y|"")
            ;;
        CHANGE)
            minimize_bind="$(ask_bind "Minimize focused window" "$minimize_bind")"
            picker_bind="$(ask_bind "Open Miniland picker" "$picker_bind")"
            shelf_bind="$(ask_bind "Show/hide Miniland shelf" "$shelf_bind")"
            ;;
        *)
            die "installation cancelled"
            ;;
    esac
fi

mkdir -p "$BIN_DIR" "$HYPR_DIR"

say "Installing $INSTALL_BIN"
download_miniland > "$INSTALL_BIN"
chmod 755 "$INSTALL_BIN"

# Always rewrite the Miniland file. This also repairs older broken bindings.
write_miniland_config

if [ "$HYPR_MODE" = "lua" ]; then
    cleanup_legacy_lua_sources
    ensure_lua_require
else
    ensure_legacy_source
fi

if command -v hyprctl >/dev/null 2>&1; then
    reload_output="$(hyprctl reload 2>&1 || true)"

    if [ -n "$reload_output" ] &&
       printf '%s' "$reload_output" | grep -qiE 'error|invalid|failed'; then
        warn "Hyprland reported a problem while reloading:"
        printf '%s\n' "$reload_output" >&2
        warn "Run: hyprctl configerrors"
    else
        say "Hyprland reloaded."
    fi

    errors="$(hyprctl configerrors 2>/dev/null || true)"
    if [ -n "$errors" ]; then
        warn "Hyprland currently reports configuration errors:"
        printf '%s\n' "$errors" >&2
    fi

    if [ "$HYPR_MODE" = "legacy" ]; then
        registered="$(hyprctl binds 2>/dev/null | grep -F "$INSTALL_BIN" || true)"
    else
        registered="$(hyprctl binds 2>/dev/null |
            grep -F -e "Minimize focused window" -e "Open Miniland picker" -e "Show or hide Miniland shelf" || true)"
    fi

    if [ -n "$registered" ]; then
        say "Verified Miniland binds through hyprctl binds."
    else
        warn "Miniland binds were not found in hyprctl binds after reload."
        if [ "$HYPR_MODE" = "lua" ]; then
            printf '%s\n' "Lua config: $MINILAND_LUA"
            printf '%s\n' "Required by:  $HYPR_CONF"
            printf '%s\n' "Try: hyprctl binds -j | grep Miniland"
        else
            printf '%s\n' "Run: hyprctl binds | grep miniland"
        fi
    fi
fi

printf '\n'
say "Miniland is installed."
printf '%s\n' "Executable: $INSTALL_BIN"

if [ "$HYPR_MODE" = "lua" ]; then
    printf '%s\n' "Module:     $MINILAND_LUA"
else
    printf '%s\n' "Config:     $MINILAND_CONF"
fi

printf '%s\n' "Minimize:   $(format_bind "$minimize_bind")"
printf '%s\n' "Picker:     $(format_bind "$picker_bind")"
printf '%s\n' "Shelf:      $(format_bind "$shelf_bind")"
printf '%s\n' "Picker default: SUPER + SHIFT + N"

if command -v fuzzel >/dev/null 2>&1 ||
   command -v wofi >/dev/null 2>&1 ||
   command -v rofi >/dev/null 2>&1; then
    say "Graphical picker backend detected."
else
    warn "No graphical picker backend found."
    printf '%s\n' "Install one of: fuzzel, wofi, or rofi-wayland/rofi."
fi

printf '%s\n' "Tip: run miniland picker to test the picker directly."
