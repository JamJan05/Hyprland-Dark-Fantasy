#!/usr/bin/env bash
#
# Installs the SDDM login theme "Dark Fantasy".
#
#   ./install-theme.sh                      - show the plan, change nothing
#   ./install-theme.sh --apply              - install and set as the default
#   ./install-theme.sh --apply --wallpaper ~/Obrazy/Tapety/moja.png
#
# Kept separate from install.sh, because THIS REQUIRES ROOT: the theme goes
# into /usr/share/sddm/themes, and the switch into /etc/sddm.conf.d.

set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dark-fantasy"
DST="/usr/share/sddm/themes/dark-fantasy"
# The file name MUST sort alphabetically AFTER kde_settings.conf.
#
# SDDM reads /etc/sddm.conf.d/*.conf alphabetically and a later file
# overrides an earlier one. Straight from the sources (src/common/ConfigReader.cpp):
#
#   order of priority from least influence to most influence, is
#     * /usr/lib/sddm/sddm.conf.d/  in alphabetical order
#     * /etc/sddm.conf.d/           in alphabetical order
#     * /etc/sddm.conf
#
# This is the OPPOSITE of systemd, where the lower number wins. Naming this
# file "10-dark-fantasy.conf" caused kde_settings.conf (the letter "k"
# sorts after the digit "1") to override it back to "breeze" - the theme
# installed correctly and was not used.
CONF="/etc/sddm.conf.d/zz-dark-fantasy.conf"
CONF_STARY="/etc/sddm.conf.d/10-dark-fantasy.conf"
STAMP="$(date +%Y%m%d-%H%M%S)"
KOPIE="/var/backups/dark-fantasy-sddm"

usage() {
    cat <<USAGE
Installs the "Dark Fantasy" SDDM login theme.

  ./install-theme.sh                    show the plan, change nothing
  ./install-theme.sh --apply            install and set as the default theme
  ./install-theme.sh --apply --wallpaper /path/to/image.png --lang pl

Options:
  --apply              really install (uses sudo)
  --wallpaper FILE     login screen wallpaper (default: the one in hyprpaper.conf)
  --lang en|pl         login screen language (default: the language chosen
                       in the shell, Cogwheel -> Language; otherwise en)
  -h, --help           show this help
USAGE
}

APPLY=0
WALLPAPER=""
JEZYK=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply)     APPLY=1; shift ;;
        --wallpaper|--lang)
            [[ $# -ge 2 ]] || { echo "$1 needs a value (see --help)" >&2; exit 2; }
            if [[ "$1" == --lang ]]; then JEZYK="$2"; else WALLPAPER="$2"; fi
            shift 2 ;;
        -h|--help)   usage; exit 0 ;;
        *) echo "Unknown argument: $1 (see --help)" >&2; exit 2 ;;
    esac
done

c_head=$'\033[1;36m'; c_ok=$'\033[0;32m'; c_warn=$'\033[0;33m'; c_off=$'\033[0m'
step() { printf '\n%s==> %s%s\n' "$c_head" "$*" "$c_off"; }
ok()   { printf '  %s✔%s %s\n' "$c_ok" "$c_off" "$*"; }
warn() { printf '  %s!%s %s\n' "$c_warn" "$c_off" "$*"; }
die()  { printf '\n  ERROR: %s\n' "$*" >&2; exit 1; }
run()  {
    if [[ "$APPLY" == 0 ]]; then
        printf '  [plan] %s\n' "$*"
        return 0
    fi
    printf '  $ %s\n' "$*"
    # Without this check a failed "sudo cp" went unnoticed
    # and the script reported success without having done anything.
    "$@" || die "command failed: $*"
}

[[ $EUID -eq 0 ]] && die "Do not run as root - the script uses sudo itself."
[[ -d "$SRC" ]] || die "Theme directory not found: $SRC"
command -v sddm >/dev/null || die "SDDM is not installed."
case "$JEZYK" in
    ""|en|pl) ;;
    *) die "--lang accepts en or pl, not: $JEZYK" ;;
esac
# The language is set with sed on the installed copy, so the key has to exist.
grep -q '^language=' "$SRC/theme.conf" || die "$SRC/theme.conf has no language= line."

# Permissions are checked UP FRONT, before we do anything.
#
# "sudo -v" asks for the password once and remembers it for the rest of the script. Without it
# every subsequent "sudo" would try to ask separately, and in an environment without
# an interactive terminal (e.g. launched by a tool that
# captures input) sudo simply aborts - the script then ended
# silently, with exit code 0, having done absolutely nothing.
if [[ "$APPLY" == 1 ]]; then
    step "Permissions"
    if ! sudo -v; then
        die "sudo did not get permissions.

        Most common cause: the script was started without an interactive
        terminal, so sudo had no way to ask for the password.
        Run it directly in a terminal window:

            cd $(dirname "$SRC")
            ./install-theme.sh --apply"
    fi
    ok "password accepted"
fi

step "Wallpaper"

# Order: --wallpaper, then the one hyprpaper uses, then the default wallpaper
# that ships with the repository (assets/wallpaper.png).
if [[ -z "$WALLPAPER" ]]; then
    # Try to read the one hyprpaper uses.
    HP="$HOME/.config/hypr/hyprpaper.conf"
    if [[ -f "$HP" ]]; then
        WALLPAPER="$(grep -oP '^\s*path\s*=\s*\K.*' "$HP" | head -1)"
        WALLPAPER="${WALLPAPER/#\~/$HOME}"
    fi
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    DOMYSLNA="$(dirname "$SRC")/../assets/wallpaper.png"
    [[ -f "$DOMYSLNA" ]] && WALLPAPER="$DOMYSLNA"
fi

if [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]]; then
    ok "using: $WALLPAPER"
else
    warn "no wallpaper found - the theme will install with a plain dark background."
    warn "Point to a file manually: --wallpaper /path/to/image.png"
    WALLPAPER=""
fi

step "Language"

# The greeter runs as the "sddm" user and cannot read the shell settings,
# so the language is decided here. Without --lang: the same rule as
# local/bin/df-jezyk - "pl" in powloka.json of the user running the script,
# anything else (or no file) means English.
if [[ -n "$JEZYK" ]]; then
    ok "$JEZYK (from --lang)"
else
    POWLOKA="${XDG_STATE_HOME:-$HOME/.local/state}/dark-fantasy/powloka.json"
    if [[ -r "$POWLOKA" ]] && grep -Eq '"jezyk"[[:space:]]*:[[:space:]]*"pl"' "$POWLOKA"; then
        JEZYK=pl
        ok "pl (from $POWLOKA)"
    else
        JEZYK=en
        ok "en (default; change with --lang pl)"
    fi
fi

step "Installing the theme to $DST"

# The backup goes OUTSIDE the themes directory. Kept next to the theme,
# every backup still had its metadata.desktop, and theme pickers (the
# Plasma SDDM module) listed several "Dark Fantasy" themes.
if [[ -d "$DST" ]]; then
    run sudo mkdir -p "$KOPIE"
    run sudo mv "$DST" "$KOPIE/dark-fantasy.bak-$STAMP"
    warn "previous version moved to $KOPIE/dark-fantasy.bak-$STAMP"
fi

run sudo mkdir -p "$DST/backgrounds"
run sudo cp "$SRC/Main.qml"          "$DST/"
run sudo cp "$SRC/metadata.desktop"  "$DST/"
run sudo cp "$SRC/theme.conf"        "$DST/"
# Only the installed copy gets the language; the repository keeps language=en.
run sudo sed -i "s/^language=.*/language=$JEZYK/" "$DST/theme.conf"
# Grain texture - Main.qml loads it via a path relative to the theme directory.
run sudo cp "$SRC/szum.png"          "$DST/"

if [[ -n "$WALLPAPER" ]]; then
    # We copy the wallpaper INTO THE THEME DIRECTORY. The greeter runs as the user
    # "sddm" and has no access to the home directory - pointing to a path
    # in ~/ would give a black background without any error message.
    run sudo cp "$WALLPAPER" "$DST/backgrounds/wallpaper.png"
fi

# The theme must be readable by the sddm user.
run sudo chmod -R a+rX "$DST"

step "Setting it as the default theme"

if [[ "$APPLY" == 1 ]]; then
    printf '  $ sudo tee %s\n' "$CONF"
    # Checked like every "run" step - a failed write used to print ok anyway.
    sudo mkdir -p "$(dirname "$CONF")" || die "cannot create $(dirname "$CONF")"
    sudo tee "$CONF" >/dev/null <<'CONFEOF' || die "writing $CONF failed"
# Login theme.
#
# The file name starts with "zz-" so that it sorts alphabetically AFTER
# kde_settings.conf, which is managed by the SDDM module in Plasma settings
# and which sets the "breeze" theme. SDDM reads this directory alphabetically,
# and a later file overrides an earlier one.
[Theme]
Current=dark-fantasy
CONFEOF
    ok "$CONF"

    # Clean up after the previous, wrongly named version.
    if [[ -f "$CONF_STARY" ]]; then
        sudo rm -f "$CONF_STARY" && warn "removed the ineffective $CONF_STARY"
    fi
else
    printf '  [plan] sudo tee %s  (sets Current=dark-fantasy)\n' "$CONF"
fi

step "Check: which theme actually wins"

# We repeat SDDM's resolution: files from /etc/sddm.conf.d in alphabetical
# order, and /etc/sddm.conf last. The last "Current=" encountered
# is the effective one.
if [[ "$APPLY" == 1 ]]; then
    WYGRYWA=""
    for f in $(ls /etc/sddm.conf.d/*.conf 2>/dev/null | sort) /etc/sddm.conf; do
        [[ -f "$f" ]] || continue
        v="$(grep -oP '^\s*Current\s*=\s*\K\S+' "$f" 2>/dev/null | tail -1)"
        [[ -n "$v" ]] && { WYGRYWA="$v"; ZRODLO="$f"; }
    done
    if [[ "$WYGRYWA" == "dark-fantasy" ]]; then
        ok "effective theme: $WYGRYWA (from $ZRODLO)"
    else
        warn "WARNING: the effective theme is \"$WYGRYWA\" (from ${ZRODLO:-nowhere}), not dark-fantasy!"
        warn "A file in /etc/sddm.conf.d sorts after ours and overrides it."
    fi
    if grep -qx "language=$JEZYK" "$DST/theme.conf"; then
        ok "login screen language: $JEZYK"
    else
        warn "WARNING: language=$JEZYK did not reach $DST/theme.conf"
    fi
fi

step "Preview without logging out"
cat <<NOTE
  sddm-greeter-qt6 --test-mode --theme $DST

  Opens the theme in a window. The real login screen shows only after
  logging out or restarting the service:
      sudo rc-service display-manager restart     (OpenRC)
      sudo systemctl restart display-manager      (systemd)
  WARNING: restarting the service CLOSES the current graphical session.
NOTE

if [[ "$APPLY" == 0 ]]; then
    printf '\n%sNothing changed.%s To run it: ./install-theme.sh --apply\n' "$c_head" "$c_off"
else
    printf '\n%sDone.%s\n' "$c_ok" "$c_off"
fi
