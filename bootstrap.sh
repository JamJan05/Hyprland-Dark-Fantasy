#!/usr/bin/env bash
#
# From-scratch installer for the Hyprland dark fantasy configuration on Gentoo.
#
#   curl -fsSL https://raw.githubusercontent.com/JamJan05/Hyprland-Dark-Fantasy/main/bootstrap.sh | bash
#       -> SHOWS the plan, changes NOTHING
#
#   curl -fsSL https://raw.githubusercontent.com/JamJan05/Hyprland-Dark-Fantasy/main/bootstrap.sh | bash -s -- --apply
#       -> does it
#
# The dry run is the default on purpose. A script fetched with curl and
# piped straight into a shell should not immediately install dozens of
# packages and change the system configuration - you should first see what
# it is going to do.
#
# What it does:
#   1. checks that this is Gentoo and that it is not running as root,
#   2. enables the GURU and hyproverlay overlays with eselect repository,
#   3. syncs them,
#   4. installs the package.accept_keywords and package.use files,
#   5. upgrades dev-libs/wayland to 1.26 and installs the packages,
#   6. clones the repository,
#   7. runs install.sh --apply, which copies the configuration,
#   8. installs the battery udev rule and (OpenRC) the dark-fantasy-stan service.
#
# Operations that need root go through sudo and are printed before they run.
# The script is idempotent - it is safe to run it again.

set -uo pipefail

REPO_URL="https://github.com/JamJan05/Hyprland-Dark-Fantasy.git"
REPO_DIR="${HYPR_REPO_DIR:-$HOME/hyprland-dark-fantasy}"
STAMP="$(date +%Y%m%d-%H%M%S)"

APPLY=0
for a in "$@"; do
    case "$a" in
        --apply) APPLY=1 ;;
        --help|-h)
            sed -n '2,26p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *) echo "Unknown argument: $a" >&2; exit 2 ;;
    esac
done

c_head=$'\033[1;36m'; c_ok=$'\033[0;32m'; c_warn=$'\033[0;33m'
c_err=$'\033[0;31m'; c_dim=$'\033[0;90m'; c_off=$'\033[0m'

step()  { printf '\n%s==> %s%s\n' "$c_head" "$*" "$c_off"; }
ok()    { printf '  %s✔%s %s\n' "$c_ok" "$c_off" "$*"; }
warn()  { printf '  %s!%s %s\n' "$c_warn" "$c_off" "$*"; }
die()   { printf '\n  %sERROR:%s %s\n' "$c_err" "$c_off" "$*" >&2; exit 1; }
plan()  { printf '  %s[plan]%s %s\n' "$c_dim" "$c_off" "$*"; }

# Run a command or only show it, depending on the mode.
run() {
    if [[ "$APPLY" == 0 ]]; then plan "$*"; return 0; fi
    printf '  %s$ %s%s\n' "$c_dim" "$*" "$c_off"
    # Checking the exit code matters here: without it a failed
    # "sudo cp" went unnoticed, and the script reported success
    # having done nothing.
    "$@" || die "command failed: $*"
}

# ------------------------------------------------------------------ checks

step "Checking the environment"

[[ $EUID -eq 0 ]] && die "Do not run this as root. The script uses sudo by itself where
        needed, and it installs the configuration into a regular user's
        home directory."

[[ -f /etc/gentoo-release ]] || die "This is not Gentoo. The script installs packages with Portage."
ok "Gentoo: $(cat /etc/gentoo-release)"

command -v emerge  >/dev/null || die "emerge command not found."
command -v git     >/dev/null || die "git command not found. Install it: sudo emerge dev-vcs/git"
command -v sudo    >/dev/null || die "sudo command not found."
ok "emerge, git, sudo found"

if command -v openrc >/dev/null 2>&1 || [[ -d /etc/runlevels ]]; then
    INIT=openrc
else
    INIT=systemd
fi
ok "Init system: $INIT"

if [[ "$INIT" == "systemd" ]]; then
    warn "The configuration was made on OpenRC + elogind. On systemd, replace"
    warn "the loginctl calls with systemctl in config/hypr/hypridle.conf"
    warn "and in config/quickshell/dark-fantasy/services/Sesja.qml."
fi

if [[ "$APPLY" == 0 ]]; then
    printf '\n%s=== DRY RUN — nothing will be changed ===%s\n' "$c_head" "$c_off"
    printf '%sTo make the changes: %s\n' "$c_dim" "curl -fsSL <url>/bootstrap.sh | bash -s -- --apply$c_off"
else
    # Privileges are checked UP FRONT, before we do anything.
    #
    # "sudo -v" asks for the password once and caches it for the rest of the script.
    # In an environment without an interactive terminal sudo has no way to ask
    # and simply aborts - without this check the script ended silently,
    # with exit code 0, having done absolutely nothing.
    #
    # Note for "curl | bash": standard input is then taken by the script
    # itself, so sudo cannot read the password from it anyway. That is why we
    # read from /dev/tty, if it is available.
    step "Privileges"
    if [[ -r /dev/tty ]]; then
        sudo -v < /dev/tty || die "sudo did not get privileges."
    else
        sudo -v || die "sudo did not get privileges.

        The script has no access to a terminal, so sudo cannot ask for
        the password. Download it to disk first and run it directly:

            curl -fsSL <url>/bootstrap.sh -o bootstrap.sh
            bash bootstrap.sh --apply"
    fi
    ok "password accepted"
fi

# ---------------------------------------------------------------- overlays

step "Portage overlays"

if ! command -v eselect >/dev/null || ! eselect repository list >/dev/null 2>&1; then
    warn "eselect repository module not found - installing it"
    run sudo emerge --noreplace app-eselect/eselect-repository
fi

for repo in guru hyproverlay; do
    if [[ -d "/var/db/repos/$repo" ]]; then
        ok "overlay $repo already enabled"
    else
        run sudo eselect repository enable "$repo"
        SYNC_NEEDED=1
    fi
done

if [[ "${SYNC_NEEDED:-0}" == 1 || "$APPLY" == 0 ]]; then
    run sudo emaint sync -r guru
    run sudo emaint sync -r hyproverlay
else
    ok "overlays already synced (skipping sync)"
fi

# ------------------------------------------------------- portage files

# Portage files are copied from the repository, so the function is defined here,
# but called only AFTER the repo is cloned - otherwise there would be nothing to copy.
fetch_portage() {  # $1 = subdirectory, $2 = target directory
    local src="$REPO_DIR/gentoo/$1/hyprland-desktop"
    local dst="/etc/portage/$1/hyprland-desktop"

    if [[ -f "$dst" ]]; then
        ok "$dst already exists - skipping"
        return 0
    fi
    if [[ ! -f "$src" ]]; then
        plan "will copy $1/hyprland-desktop from the repository (after cloning)"
        return 0
    fi
    run sudo mkdir -p "/etc/portage/$1"
    run sudo cp "$src" "$dst"
}

step "Configuration repository"

if [[ -d "$REPO_DIR/.git" ]]; then
    ok "$REPO_DIR already exists"
    run git -C "$REPO_DIR" pull --ff-only
elif [[ -f "$(dirname "${BASH_SOURCE[0]}")/install.sh" ]]; then
    REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ok "running from inside the repository: $REPO_DIR"
else
    run mkdir -p "$(dirname "$REPO_DIR")"
    run git clone "$REPO_URL" "$REPO_DIR"
fi

step "Keywords and USE flags"
fetch_portage package.accept_keywords
fetch_portage package.use

# libwayland 1.26 - reason in gentoo/package.accept_keywords/hyprland-desktop.
# fetch_portage skips a file that already exists, so a copy from before this
# entry was added gets the line appended. portageq asks Portage itself, so
# a keyword set in any other file counts as well.
WAYLAND_ATOM=">=dev-libs/wayland-1.26.0"
KEYWORDS_FILE=/etc/portage/package.accept_keywords/hyprland-desktop
if [[ -n "$(portageq best_visible / "$WAYLAND_ATOM" 2>/dev/null)" ]]; then
    ok "dev-libs/wayland 1.26 is visible to Portage"
elif [[ -f "$KEYWORDS_FILE" ]]; then
    run sudo sh -c "printf '%s\n' '$WAYLAND_ATOM ~amd64' >> '$KEYWORDS_FILE'"
else
    plan "the copied package.accept_keywords/hyprland-desktop will unmask $WAYLAND_ATOM"
fi

# --------------------------------------------------------------- packages

step "Packages"

PAKIETY=(
    gui-wm/hyprland
    gui-apps/waybar
    gui-apps/swaync
    gui-apps/hyprlock
    gui-apps/hypridle
    gui-apps/hyprpaper
    gui-apps/hyprshot
    gui-apps/wl-clipboard
    app-misc/cliphist
    gui-apps/rofi-wayland
    sys-auth/hyprpolkitagent
    gui-libs/xdg-desktop-portal-hyprland
    media-fonts/nerdfonts
    media-sound/playerctl
    media-video/pipewire
    media-video/wireplumber
    gui-apps/grim
    gui-apps/slurp
    app-misc/jq
    x11-terms/kitty
    app-misc/brightnessctl

    # Required by the shell and the bar. Without them the desktop still comes up,
    # but the corresponding elements will be empty or show an "unavailable" state.
    sys-power/power-profiles-daemon   # power profile in the Cogwheel
    net-wireless/bluez                # Bluetooth: bar and Cogwheel
    dev-python/dbus-python            # Bluetooth pairing agent (local/bin/df-agent-bt)
    dev-python/pygobject              # its main loop

    # File manager behind SUPER+W (fileManager variable in hyprland.lua).
    # Yazi is a terminal program, so it is launched by the
    # local/bin/menedzer-plikow wrapper. It lives in the "guru" overlay.
    app-misc/yazi

    # Full-screen clock in the terminal - handy as a screensaver
    # or a clock on a second monitor. No keybinding; you launch it yourself
    # with the "tty-clock" command.
    app-misc/tty-clock

    # Dark Souls-style look. Each of these packages has its place
    # in the configuration - without it, that element silently falls back to the
    # default look instead of breaking.
    media-fonts/eb-garamond           # typeface for text: headings, date, hyprlock, SDDM
    x11-themes/adw-gtk3               # GTK 3 theme (guru); palette in config/gtk-*/gtk.css
    x11-themes/papirus-icon-theme     # Papirus-Dark icons for GTK
    x11-themes/bibata-xcursors        # Bibata-Original-Classic cursor (guru)
    sys-process/btop                  # system monitor behind the Status tile
    dev-python/pillow                 # cover art on the bar, noise texture, tile icons

    # QtQuick shell: HUD, tile row (Arsenal, Tidings, Cogwheel,
    # Bonfire), panels, OSD and notifications.
    # It lives in the "guru" overlay, which this script enables above.
    # Version 0.3.1 is under ~amd64, and its default USE pulls in
    # dev-cpp/cpptrace[unwind] - both are handled by the files
    # from the gentoo/ directory copied in the "Keywords and USE flags" step.
    gui-apps/quickshell
)

# User programs (browser, messengers, games) are NOT installed -
# those are personal choices, not part of the desktop. The Arsenal shows whatever
# is installed.

printf '  %s%d packages:%s %s\n' "$c_dim" "${#PAKIETY[@]}" "$c_off" "${PAKIETY[*]}"

# --changed-use rebuilds whatever had its flags changed - in practice
# Waybar, which without USE="wifi" does not show the network signal strength.
#
# libwayland first, as a separate --oneshot: it is only a dependency, so it
# should not land in the world file, and plain "emerge hyprland" would not
# upgrade an already installed 1.25 (no --deep). Nothing happens if 1.26 or
# newer is already installed.
if [[ "$APPLY" == 1 ]]; then
    sudo emerge --ask --verbose --oneshot --update "$WAYLAND_ATOM" \
        || die "emerge of $WAYLAND_ATOM failed. Fix the problem and run the script again."
    warn "This will take a while. Hyprland and the Qt dependencies take long to compile."
    sudo emerge --ask --verbose --changed-use "${PAKIETY[@]}" \
        || die "emerge failed. Fix the problem and run the script again."
else
    plan "sudo emerge --ask --verbose --oneshot --update \"$WAYLAND_ATOM\""
    plan "sudo emerge --ask --verbose --changed-use <the packages above>"
fi

# ----------------------------------------------------------- configuration

step "Configuration"

if [[ "$APPLY" == 1 ]]; then
    bash "$REPO_DIR/install.sh" --apply
else
    plan "$REPO_DIR/install.sh --apply"
fi

# Battery charge limit without a password prompt - only on hardware that
# exposes charge thresholds (ThinkPad: thinkpad_acpi). Rationale
# in the rule's header.
REGULA=/etc/udev/rules.d/99-dark-fantasy-bateria.rules
if ls /sys/class/power_supply/BAT*/charge_control_end_threshold >/dev/null 2>&1; then
    if [[ -f "$REGULA" ]]; then
        ok "$REGULA already exists"
    else
        # /etc/udev/rules.d does not have to exist - on Gentoo package rules
        # live in /lib/udev/rules.d, and cp into a missing directory fails.
        run sudo mkdir -p "$(dirname "$REGULA")"
        run sudo cp "$REPO_DIR/udev/99-dark-fantasy-bateria.rules" "$REGULA"
        run sudo udevadm trigger --subsystem-match=power_supply --action=change
    fi
else
    ok "battery has no charge thresholds - skipping the udev rule"
fi

# Backlight and SDDM Num Lock from the last session already before login -
# pamiec-ustawien alone restores them only after it. Rationale in the
# script's header. OpenRC only; on systemd, systemd-backlight covers the
# screen backlight.
USLUGA=/etc/init.d/dark-fantasy-stan
if [[ "$INIT" != "openrc" ]]; then
    ok "not OpenRC - skipping $USLUGA"
else
    if [[ -f "$USLUGA" ]] && cmp -s "$REPO_DIR/openrc/dark-fantasy-stan" "$USLUGA"; then
        ok "$USLUGA already installed"
    else
        run sudo install -o root -g root -m 0755 "$REPO_DIR/openrc/dark-fantasy-stan" "$USLUGA"
    fi
    # Checked separately from the file: an up-to-date script that is not in
    # the runlevel would never run.
    if rc-update show default 2>/dev/null | grep -qw dark-fantasy-stan; then
        ok "dark-fantasy-stan already in the default runlevel"
    else
        run sudo rc-update add dark-fantasy-stan default
    fi
fi

# ------------------------------------------------------------------ finish

step "Still to do by hand"

cat <<NOTE
  1. Wallpaper - the default one ships with the repository (assets/wallpaper.png).
       Put your own images in ~/Pictures/Wallpapers and pick one in the Cogwheel
       (SUPER+U, Hyprland -> Wallpaper).

  2. Bluetooth - the bar module shows Bluetooth as off until the service is running:
NOTE
if [[ "$INIT" == "openrc" ]]; then
cat <<'NOTE'
       sudo rc-service bluetooth start
       sudo rc-update add bluetooth default
NOTE
else
cat <<'NOTE'
       sudo systemctl enable --now bluetooth
NOTE
fi
cat <<'NOTE'

  3. Login screen (optional), in the repository directory:
       cd sddm && ./install-theme.sh --apply

  4. Start Hyprland (from a TTY: Hyprland) or reload it: hyprctl reload
NOTE

if [[ "$APPLY" == 0 ]]; then
    printf '\n%sNothing was changed.%s To make the changes, add %s--apply%s\n' \
        "$c_head" "$c_off" "$c_head" "$c_off"
else
    printf '\n%sDone.%s\n' "$c_ok" "$c_off"
fi
