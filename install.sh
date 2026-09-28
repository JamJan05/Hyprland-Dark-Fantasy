#!/usr/bin/env bash
#
# Configuration installer. COPIES the files from this repository into
# ~/.config and related directories - no symbolic links. After installation
# the repository folder is not needed: it can be deleted, and to change
# something later you clone it again, edit, run --apply and delete it again.
#
#   ./install.sh          - show what will be done, change nothing
#   ./install.sh --apply  - do it
#
# LOCAL CHANGES SURVIVE A REINSTALL. Some installed files change on their own
# in the running system: the Cogwheel writes the wallpaper into hyprpaper.conf
# and hyprlock.conf, kde-gtk-config rewrites gtk.css. A plain copy would wipe
# that on every run, so the checksum of every installed file is recorded in
# $XDG_STATE_HOME/dark-fantasy/instalacja.sha256 and each file is decided
# separately:
#
#   system file identical to the repo          -> nothing to do
#   system file missing                        -> copied
#   system file untouched since last install   -> updated from the repo
#   changed locally, repo file unchanged       -> local change kept
#   changed on both sides, or no record        -> system version moved to
#                                                 <file>.bak-<date>, repo copied
#
# Symlinks left by the old, link-based installer are replaced by copies.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
APPLY=0
[[ "${1:-}" == "--apply" ]] && APPLY=1

MANIFEST="${XDG_STATE_HOME:-$HOME/.local/state}/dark-fantasy/instalacja.sha256"

info()  { printf '\033[0;36m%s\033[0m\n' "$*"; }
ok()    { printf '  \033[0;32m✔\033[0m %s\n' "$*"; }
warn()  { printf '  \033[0;33m!\033[0m %s\n' "$*"; }

# In a dry run the verbs describe the plan, with --apply what was done.
czyn() {  # $1 = dry-run text, $2 = apply text
    if [[ "$APPLY" == 0 ]]; then echo "  $1"; else ok "$2"; fi
}

declare -A POPRZEDNIE=()   # target -> checksum at the last install
declare -A OBECNE=()       # target -> checksum installed by this run
if [[ -r "$MANIFEST" ]]; then
    while read -r suma sciezka; do
        [[ -n $sciezka ]] && POPRZEDNIE[$sciezka]=$suma
    done < "$MANIFEST"
fi

suma() { sha256sum < "$1" | cut -d' ' -f1; }

# Copy through a temporary file and a rename: a program reading the file at
# that moment (Hyprland watches its config) never sees half of it, and the
# rename also replaces an old symlink instead of writing through it.
wgraj() {  # $1 = source, $2 = target
    mkdir -p "$(dirname "$2")" &&
    cp -p "$1" "$2.tmp-$STAMP" &&
    mv -f "$2.tmp-$STAMP" "$2"
}

kopiuj_plik() {  # $1 = absolute source, $2 = absolute target
    local src="$1" dst="$2" hs hd stara
    hs=$(suma "$src")
    stara=${POPRZEDNIE[$dst]:-}

    if [[ -L "$dst" ]]; then
        czyn "$dst  <-  ${src#"$REPO"/}  (symlink replaced by a copy)" "$dst (symlink replaced by a copy)"
        # No rm first: the rename replaces the link in one step. With rm, Hyprland
        # caught the moment without hyprland.lua and reported a config error.
        [[ "$APPLY" == 1 ]] && wgraj "$src" "$dst"
    elif [[ ! -e "$dst" ]]; then
        czyn "$dst  <-  ${src#"$REPO"/}" "$dst"
        [[ "$APPLY" == 1 ]] && wgraj "$src" "$dst"
    else
        hd=$(suma "$dst")
        if [[ $hd == "$hs" ]]; then
            [[ -z ${CICHO:-} ]] && ok "up to date: $dst"
        elif [[ -n $stara && $hd == "$stara" ]]; then
            czyn "$dst  <-  ${src#"$REPO"/}  (update)" "updated: $dst"
            [[ "$APPLY" == 1 ]] && wgraj "$src" "$dst"
        elif [[ -n $stara && $hs == "$stara" ]]; then
            ok "kept your local change: $dst"
        else
            if [[ "$APPLY" == 0 ]]; then
                echo "  $dst  <-  ${src#"$REPO"/}  (your version goes to .bak-$STAMP)"
            else
                mv "$dst" "$dst.bak-$STAMP" && wgraj "$src" "$dst"
                warn "your version backed up as: $dst.bak-$STAMP"
            fi
        fi
    fi
    OBECNE[$dst]=$hs
}

kopiuj() {  # $1 = source in the repo (relative), $2 = absolute target
    local src="$REPO/$1" dst="$2" f sciezka

    if [[ ! -e "$src" ]]; then
        warn "missing from the repo: $1"
        return 1
    fi

    if [[ -f "$src" ]]; then
        kopiuj_plik "$src" "$dst"
        return
    fi

    # A directory: file by file, so the same rules apply to every file.
    if [[ -L "$dst" ]]; then
        czyn "$dst/  <-  $1/  (symlink replaced by a copy)" "$dst/ (symlink replaced by a copy)"
        [[ "$APPLY" == 1 ]] && rm -f "$dst"
    fi
    while IFS= read -r -d '' f; do
        CICHO=1 kopiuj_plik "$f" "$dst/${f#"$src"/}"
    done < <(find "$src" -type f -not -path '*/__pycache__/*' -print0 | sort -z)

    # Files installed last time that are gone from the repo. Left in place,
    # a stale .qml file in the shell directory would still be picked up by
    # Quickshell as a component.
    for sciezka in "${!POPRZEDNIE[@]}"; do
        [[ $sciezka == "$dst"/* && -z ${OBECNE[$sciezka]:-} && -f $sciezka ]] || continue
        if [[ $(suma "$sciezka") == "${POPRZEDNIE[$sciezka]}" ]]; then
            czyn "remove $sciezka  (gone from the repo)" "removed (gone from the repo): $sciezka"
            [[ "$APPLY" == 1 ]] && rm -f "$sciezka"
        else
            warn "gone from the repo, but changed locally - left in place: $sciezka"
        fi
    done
    [[ "$APPLY" == 1 ]] && ok "$dst/"
}

[[ "$APPLY" == 0 ]] && info "=== DRY RUN (add --apply to make the changes) ==="

info "Hyprland"
kopiuj config/hypr/hyprland.lua   "$HOME/.config/hypr/hyprland.lua"
kopiuj config/hypr/floors.lua     "$HOME/.config/hypr/floors.lua"
kopiuj config/hypr/hyprlock.conf  "$HOME/.config/hypr/hyprlock.conf"
kopiuj config/hypr/hypridle.conf  "$HOME/.config/hypr/hypridle.conf"
kopiuj config/hypr/hyprpaper.conf "$HOME/.config/hypr/hyprpaper.conf"

info "Waybar"
for f in config.jsonc style.css; do
    kopiuj "config/waybar/$f" "$HOME/.config/waybar/$f"
done

# SwayNC is NOT the notification daemon - Quickshell is
# (config/quickshell/dark-fantasy, services/Notifications.qml), and SwayNC
# is not started from the autostart in hyprland.lua.
#
# Its configuration is still installed on purpose: the package is still
# installed, and restoring one autostart line and pointing the .service
# file at swaync is enough to switch back. Without these files, going back
# would mean configuring it from scratch.
info "SwayNC (inactive - config kept as a fallback)"
kopiuj config/swaync/config.json "$HOME/.config/swaync/config.json"
kopiuj config/swaync/style.css   "$HOME/.config/swaync/style.css"

# Fish: fastfetch moved here from /etc/fish/config.fish, where it sat without
# the "status is-interactive" condition and also fired in non-interactive
# shells, cluttering the output of "fish -c ...".
info "fish shell"
kopiuj config/fish/config.fish "$HOME/.config/fish/config.fish"
# fastfetch without the local IP address - reason in the file's header.
kopiuj config/fastfetch/config.jsonc "$HOME/.config/fastfetch/config.jsonc"

info "rofi (clipboard history), kitty"
kopiuj config/rofi/dark-fantasy.rasi      "$HOME/.config/rofi/dark-fantasy.rasi"
kopiuj config/kitty/kitty.conf            "$HOME/.config/kitty/kitty.conf"
# Second kitty config for the panel window (Status) - passed by the
# monitor-systemu wrapper, see the panel.conf header.
kopiuj config/kitty/panel.conf            "$HOME/.config/kitty/panel.conf"

# Themes for the terminal programs behind the Satchel and Status tiles.
info "yazi and btop (palette themes)"
kopiuj config/yazi/theme.toml              "$HOME/.config/yazi/theme.toml"
kopiuj config/btop/btop.conf               "$HOME/.config/btop/btop.conf"
kopiuj config/btop/themes/dark-fantasy.theme "$HOME/.config/btop/themes/dark-fantasy.theme"

# GTK: settings.ini (adw-gtk3 theme, Papirus icons, Bibata cursor) and
# gtk.css with the dark-fantasy palette and zero corner radius.
#
# colors.css and window_decorations.css are generated by kde-gtk-config when the
# Plasma theme changes - we do not install those. kde-gtk-config can also
# rewrite gtk.css (a theme change in Plasma System Settings); that counts as
# a local change and is kept. To get the palette from the repo back, delete
# ~/.config/gtk-*/gtk.css and run ./install.sh --apply.
info "GTK (look of GTK apps: theme, icons, cursor, palette)"
for v in 3.0 4.0; do
    kopiuj "config/gtk-$v/settings.ini" "$HOME/.config/gtk-$v/settings.ini"
    kopiuj "config/gtk-$v/gtk.css"      "$HOME/.config/gtk-$v/gtk.css"
done

info "xdg-desktop-portal"
kopiuj config/xdg-desktop-portal/hyprland-portals.conf \
       "$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"

info "Quickshell (HUD, tile row, panels, OSD, notifications)"
# The WHOLE directory is installed, not a list of files. The Quickshell
# shell is a dozen or so QML files, and more keep arriving as panels
# get added - listing them one by one would mean coming back
# to this script for every new component.
#
# Launch:  qs -c dark-fantasy
kopiuj config/quickshell/dark-fantasy "$HOME/.config/quickshell/dark-fantasy"

info "Helper scripts (called by Waybar and keybindings)"
for f in df-agent-bt df-jezyk limit-ladowania menedzer-plikow monitor-systemu pamiec-ustawien uklad-startowy waybar-data waybar-okladka waybar-odtwarzacz waybar-temperatura zrzut-ekranu; do
    kopiuj "local/bin/$f" "$HOME/.local/bin/$f"
done

info "Quickshell shell as the notification daemon (D-Bus)"
kopiuj local/share/dbus-1/services/org.freedesktop.Notifications.service \
       "$HOME/.local/share/dbus-1/services/org.freedesktop.Notifications.service"

# Icons for the menu tiles at the bottom of the screen (kafle/Kafel.qml).
#
# The originals (512 px, assets/ikony-menu/) never go into the shell.
# The script makes 256 px versions of them in assets/ikony-menu/256/, and the shell
# reads them from the FIXED path ~/.local/share/dark-fantasy/ikony-menu,
# where they are copied. A fixed path, because the repository may not exist
# once installed, so nothing may point into it.
info "Tile menu icons"
if [[ "$APPLY" == 1 ]]; then
    if command -v python3 >/dev/null && python3 -c 'import PIL' 2>/dev/null; then
        ( cd "$REPO" && python3 tools/skaluj-ikony-menu.py ) \
            || warn "an original is missing from assets/ikony-menu/ - its tile will show an empty square with the name"
    else
        warn "python3 with Pillow (dev-python/pillow) not found - tile icons were not generated"
    fi
fi
kopiuj assets/ikony-menu/256 "${XDG_DATA_HOME:-$HOME/.local/share}/dark-fantasy/ikony-menu"

# No wallpaper ships with the repository. The Cogwheel lists images from
# <XDG Pictures>/Wallpapers (or an existing .../Tapety) and writes the chosen
# one into hyprpaper.conf and hyprlock.conf.
info "Wallpaper"
OBRAZY="$(xdg-user-dir PICTURES 2>/dev/null || true)"
[[ -z $OBRAZY || $OBRAZY == "$HOME" ]] && OBRAZY="$HOME/Pictures"
TAPETY="$OBRAZY/Wallpapers"
[[ ! -d $TAPETY && -d $OBRAZY/Tapety ]] && TAPETY="$OBRAZY/Tapety"
# The default wallpaper (assets/wallpaper.png): copied to a fixed path that
# hyprpaper.conf and hyprlock.conf point to, so it works whatever the XDG
# Pictures folder is called. A copy also lands in an EMPTY wallpaper folder,
# so the Cogwheel list is not empty on a fresh install.
kopiuj assets/wallpaper.png "${XDG_DATA_HOME:-$HOME/.local/share}/dark-fantasy/wallpaper.png"
if compgen -G "$TAPETY/*.[pPjJwW]*" >/dev/null; then
    ok "$TAPETY"
elif [[ "$APPLY" == 1 ]]; then
    mkdir -p "$TAPETY" && cp "$REPO/assets/wallpaper.png" "$TAPETY/wallpaper.png" && ok "$TAPETY/wallpaper.png"
else
    echo "  $TAPETY/wallpaper.png  <-  assets/wallpaper.png (copy)"
fi

# The record is written only with --apply and only at the end, so an
# interrupted run leaves the previous one in place.
if [[ "$APPLY" == 1 ]]; then
    mkdir -p "$(dirname "$MANIFEST")"
    for sciezka in "${!OBECNE[@]}"; do
        printf '%s  %s\n' "${OBECNE[$sciezka]}" "$sciezka"
    done | sort -k2 > "$MANIFEST.tmp-$STAMP" && mv -f "$MANIFEST.tmp-$STAMP" "$MANIFEST"
fi

echo
if [[ "$APPLY" == 0 ]]; then
    info "Nothing was changed. Run: ./install.sh --apply"
else
    info "Done. The repository folder is no longer needed - you can delete it."
    info "Still to do by hand:"
    cat <<'NOTE'
  1. Portage files (need root):
       sudo cp gentoo/package.accept_keywords/hyprland-desktop /etc/portage/package.accept_keywords/
       sudo cp gentoo/package.use/hyprland-desktop             /etc/portage/package.use/
  2. Login screen (optional): cd sddm && ./install-theme.sh --apply
  3. Battery charge limit without a password prompt (laptops with charge thresholds):
       sudo mkdir -p /etc/udev/rules.d
       sudo cp udev/99-dark-fantasy-bateria.rules /etc/udev/rules.d/
       sudo udevadm trigger --subsystem-match=power_supply --action=change
  4. CPU power limit per profile (AMD Ryzen laptops, optional) - ryzenadj in
     /usr/local/bin, iomem=relaxed on the kernel command line, then:
       sudo install -o root -g root -m 0755 sbin/df-limit-mocy /usr/local/sbin/
       sudo install -d -o root -g root -m 0750 /etc/sudoers.d
       sudo visudo -cf sudoers/dark-fantasy-moc && \
         sudo install -o root -g root -m 0440 sudoers/dark-fantasy-moc /etc/sudoers.d/
     Details: docs/installation.md, "CPU power limit (ryzenadj)".
  5. Backlight and SDDM Num Lock from the last session already before login
     (OpenRC):
       sudo install -o root -g root -m 0755 openrc/dark-fantasy-stan /etc/init.d/
       sudo rc-update add dark-fantasy-stan default
  6. Reload: hyprctl reload
NOTE
fi
