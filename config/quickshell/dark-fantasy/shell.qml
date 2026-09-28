//@ pragma IconTheme Papirus-Dark

// The pragma MUST sit above the imports: Quickshell reads it at startup,
// before loading the rest (src/launch/launch.cpp), so it only takes effect
// after a shell restart, not after a reload.
//
// Papirus-Dark icon theme - the same as gtk-icon-theme-name
// in config/gtk-3.0/settings.ini, so a program has the same icon in the
// Arsenal grid as in GTK windows. Without this line Qt looked for icons
// only in hicolor and lost everything that is not there.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  HYPRLAND DARK FANTASY - QUICKSHELL SHELL.
//
//  This file is meant to be SHORT. Its only jobs are:
//      - bring the panels to life,
//      - give them a way to open and close.
//  All the content lives in hud/, kafle/, system/, media/, notifications/,
//  osd/ and components/.
//
//  ---------------------------------------------------------------
//  STARTING
//
//      qs -c dark-fantasy
//
//  In AUTOSTART always with the -n flag:
//
//      qs -n -c dark-fantasy
//
//  Without it Quickshell allows starting a second instance of the same
//  config. The symptom is subtle - the panel looks normal,
//  but "hyprctl layers" shows two "quickshell-kafle" layers
//  stacked on each other, and "qs ipc call" randomly hits one of them,
//  so the panel stops responding every other click.
//
//  The process name is "qs", not "quickshell" - pgrep -x quickshell
//  finds nothing, even though the shell is running.
//
//  ---------------------------------------------------------------
//  HOW TO OPEN A PANEL
//
//  1. From the command line or from Waybar:
//         qs -c dark-fantasy ipc call kafle otworz zebatka
//     Hooking this up to a click on the bar is one "on-click"
//     line in config/waybar/config.jsonc.
//
//  2. With a keyboard shortcut - the GlobalShortcut below registers
//     itself in Hyprland via the global-shortcuts protocol. The key
//     is assigned on the hyprland.lua side:
//         hl.bind(mainMod .. " + U", hl.dsp.global("quickshell:systemToggle"))
//
//  This is deliberately NOT "hyprctl dispatch exec", because then every
//  panel opening would start a new process.
//
//  ---------------------------------------------------------------
//  ONE MONITOR
//
//  The panel appears on the default monitor. For multi-screen work
//  it has to be wrapped in Variants over Quickshell.screens -
//  at this stage that would be complicating something there is
//  no way to test yet.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

// QtQml - for Component.onCompleted below. Without this import Quickshell
// rejects the whole file with "Non-existent attached object".
import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.hud
import qs.kafle
import qs.media
import qs.notifications
import qs.services
import qs.osd
import qs.system

ShellRoot {
    id: root

    // Panel open state is kept HERE, not in the panels
    // themselves. That way a rule like "opening media closes the
    // system panel" can later be added in one place,
    // instead of scattering it across components.
    property bool mediaOpen: false

    // Singletons are created lazily - this binding makes sure hyprlock's
    // language file is written at startup, not only after a change.
    readonly property string jezykHyprlocka: JezykZewnetrzny.tekstHyprlocka

    // Quick panel mode: "wifi", "bluetooth" or empty.
    property string quickMode: ""

    // Pause: tile menu at the bottom of the screen with a dimmed desktop.
    property bool pauzaOpen: false

    // Cogwheel = pause with the Cogwheel tile selected. Not a separate state, just
    // a view over two existing ones - a separate flag would have to be reset on every
    // pause close and on every tile change.
    readonly property bool zebatkaOpen: pauzaOpen && kafle.kafel.klucz === "zebatka"

    function przelaczZebatke(): void {
        if (zebatkaOpen) {
            pauzaOpen = false;
            return;
        }
        kafle.wejdz("zebatka");
        pauzaOpen = true;
    }

    // Next power-profiles-daemon profile, cycling: power saver ->
    // balanced -> performance (the latter only if the hardware reports it).
    // Confirmation is shown by the OSD, which listens for profile changes itself.
    function przelaczProfil(): void {
        const kolejnosc = [PowerProfile.PowerSaver, PowerProfile.Balanced];
        if (PowerProfiles.hasPerformanceProfile) kolejnosc.push(PowerProfile.Performance);
        const i = kolejnosc.indexOf(PowerProfiles.profile);
        PowerProfiles.profile = kolejnosc[(i + 1) % kolejnosc.length];
    }

    // The charge limit has to be restored at session start, not on the first
    // Cogwheel opening - a singleton is only created on first
    // reference, so we wake it up here.
    Component.onCompleted: {
        Ladowanie.odswiez();
        // Also wakes the singleton, which then follows profile changes itself.
        LimitMocy.zastosuj();
        // Bluetooth on/off from before the shutdown (services/PamiecBluetooth.qml).
        PamiecBluetooth.start();
    }

    // Player. A separate panel, slides out from the MIDDLE of the bar - from
    // under the media module.
    MediaPanel {
        open: root.mediaOpen
        onCloseRequested: root.mediaOpen = false
    }

    // Tooltips. They have no open state - they show up on their own when a
    // notification arrives, and disappear after a while. Control in services/Notifications.qml.
    NotificationPopups {}

    // Notification history is under the Tidings tile (kafle/Wiesci.qml).

    // Quick panel from under the network or Bluetooth icon. Same content
    // as the Network and Bluetooth sections in Cogwheel - see system/QuickPanel.qml.
    QuickPanel {
        id: szybki
        mode: root.quickMode
        onCloseRequested: root.quickMode = ""
        onOpenRequested: function (co) { root.quickMode = co; }
    }

    // All three panels are mutually exclusive. Each one spreads
    // its own full-screen click catcher, so two open at once
    // means a click outside closes one of them at random.
    onMediaOpenChanged: if (mediaOpen) zamknijPozostale("media");
    onQuickModeChanged: if (quickMode !== "") zamknijPozostale("quick");
    onPauzaOpenChanged: if (pauzaOpen) zamknijPozostale("pauza");

    function zamknijPozostale(ktory: string) {
        if (ktory !== "media") mediaOpen = false;
        if (ktory !== "quick") quickMode = "";
        if (ktory !== "pauza") pauzaOpen = false;
    }

    // Tile row at the bottom edge - the dock and the app menu. Visible on an
    // empty desktop, and in pause dims the screen and takes the keyboard.
    // Description in kafle/RzadKafli.qml.
    //
    // What using a tile does is decided HERE, not by the row: tiles open
    // panels whose state the shell holds anyway. Satchel and Status launch
    // programs in windows; the remaining tiles have content above the row.
    RzadKafli {
        id: kafle

        pauza: root.pauzaOpen
        innyPanel: root.mediaOpen || root.quickMode !== ""
        onPauzaProszona: root.pauzaOpen = true
        onZamkniecieProszone: root.pauzaOpen = false

        onUzyto: function (klucz) {
            root.pauzaOpen = false;
            // Arsenal, Tidings, Cogwheel and Bonfire never get here - they have
            // their own content above the tile row and do not call "uzyto".
            switch (klucz) {
            case "sakwa":
                // Full path: the PATH of a shell started from autostart does not
                // have to contain ~/.local/bin.
                Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/menedzer-plikow"]);
                break;
            case "status":
                // btop in a panel window - the wrapper sets the df-panel class
                // and passes the theme. Satchel (yazi), on the other hand, opens as
                // a regular tiled window - see local/bin/menedzer-plikow.
                Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/monitor-systemu"]);
                break;
            }
        }
    }

    // HUD in the left corner of the bar: floor emblem, HP/FP/stamina bars, the floor's
    // desktops and stacking statuses. It has no open state - it is always there.
    // Description in hud/Hud.qml.
    Hud {
        id: hud
    }

    // OSD - a brief preview on volume and brightness changes.
    //
    // It has no control input of its own: it listens to the Audio and
    // Brightness services itself and shows up when something changes. The only
    // thing we pass to it is whether Cogwheel is open -
    // then the OSD stays silent, since Cogwheel shows the same sliders anyway.
    Osd {
        suppressed: root.zebatkaOpen
    }

    // ---------------------------------------------------------------
    //  EXTERNAL CONTROL
    //
    //  "qs ipc call system toggle" - opens Cogwheel in pause. The target
    //  name is left over from System Control Center, so as not to break scripts.
    //  Functions must have explicit types, otherwise Quickshell will not
    //  expose them. "qs ipc show" lists the registered targets.
    // ---------------------------------------------------------------
    IpcHandler {
        target: "system"

        function toggle(): void {
            root.przelaczZebatke();
        }

        function open(): void {
            if (!root.zebatkaOpen) root.przelaczZebatke();
        }

        function close(): void {
            if (root.zebatkaOpen) root.pauzaOpen = false;
        }

        function isOpen(): bool {
            return root.zebatkaOpen;
        }
    }

    IpcHandler {
        target: "media"

        function toggle(): void {
            root.mediaOpen = !root.mediaOpen;
        }

        function open(): void {
            root.mediaOpen = true;
        }

        function close(): void {
            root.mediaOpen = false;
        }

        function isOpen(): bool {
            return root.mediaOpen;
        }
    }

    // Quick panels invoked by clicking the network or Bluetooth icon
    // on the bar. Clicking the same icon again closes; clicking the
    // other one switches the content without closing and reopening.
    IpcHandler {
        target: "quick"

        function toggle(co: string): void {
            if (root.quickMode === co) root.quickMode = "";
            else szybki.request(co);
        }

        function close(): void {
            root.quickMode = "";
        }

        function current(): string {
            return root.quickMode;
        }
    }

    // Notification history (Tidings tile) and "do not disturb" mode - for
    // scripts and shortcuts.
    IpcHandler {
        target: "notifications"

        // The notification center is now the Tidings tile in pause.
        function toggle(): void {
            if (root.pauzaOpen && kafle.kafel.klucz === "wiesci") {
                root.pauzaOpen = false;
                return;
            }
            kafle.wejdz("wiesci");
            root.pauzaOpen = true;
        }

        function close(): void {
            if (kafle.kafel.klucz === "wiesci") root.pauzaOpen = false;
        }

        function toggleDnd(): void {
            Notifications.toggleDnd();
        }

        // Handy in a script or under a shortcut - and it was needed
        // to clean up after tests.
        function clear(): void {
            Notifications.clearAll();
        }
    }

    // Tile menu (pause). "otworz" takes a tile key: uzbrojenie,
    // sakwa, status, wiesci, zebatka, ognisko.
    IpcHandler {
        target: "kafle"

        function toggle(): void {
            root.pauzaOpen = !root.pauzaOpen;
        }

        function otworz(klucz: string): void {
            kafle.wejdz(klucz);
            root.pauzaOpen = true;
        }

        function zamknij(): void {
            root.pauzaOpen = false;
        }

        function pauza(): bool {
            return root.pauzaOpen;
        }
    }

    // Power profile and charge limit - for scripts. "limit" without a password
    // window works only with the udev rule (services/Ladowanie.qml).
    IpcHandler {
        target: "zasilanie"

        function przelaczProfil(): void {
            root.przelaczProfil();
        }

        function profil(): string {
            return PowerProfiles.profile === PowerProfile.PowerSaver ? "power-saver"
                 : PowerProfiles.profile === PowerProfile.Performance ? "performance"
                                                                       : "balanced";
        }

        function limit(procent: int): void {
            Ladowanie.ustaw(procent);
        }

        function limitLadowania(): int {
            return Ladowanie.koniec;
        }
    }

    // Left-corner HUD.
    //
    // "liczby" returns JSON for the "custom/zasoby" module in Waybar -
    // CPU, memory and battery as numbers when the HUD bars are off
    // (empty text when they are on). "przelaczPaski" is the same switch
    // that is in Cogwheel (System -> Behavior).
    IpcHandler {
        target: "hud"

        function przelaczPaski(): void {
            UstawieniaPowloki.przelaczPaski();
        }

        function paski(): bool {
            return UstawieniaPowloki.hudBars;
        }

        function liczby(): string {
            return hud.liczby();
        }
    }

    // Interface language - for scripts (Waybar, hyprlock) and tests.
    // "qs ipc call jezyk ustaw pl" switches, "kod" returns "en"/"pl".
    IpcHandler {
        target: "jezyk"

        function ustaw(kod: string): void {
            UstawieniaPowloki.ustawJezyk(kod);
        }

        function kod(): string {
            return Tr.kod;
        }
    }

    // Idle inhibit - for scripts and shortcuts. The switch is
    // in Cogwheel (System -> Behavior).
    IpcHandler {
        target: "idle"

        function toggle(): void {
            Idle.toggle();
        }

        function isOn(): bool {
            return Idle.inhibited;
        }
    }

    // ---------------------------------------------------------------
    //  KEYBOARD SHORTCUT
    //
    //  Registers in the compositor under the name "quickshell:systemToggle".
    //  By itself it does not bind any key - that is done by
    //  hyprland.lua, see the file header.
    // ---------------------------------------------------------------
    GlobalShortcut {
        appid: "quickshell"
        name: "systemToggle"
        description: "Open or close Cogwheel (settings)"

        onPressed: root.przelaczZebatke()
    }

    // SUPER+R. The shortcut name is left over from the app menu, so as not to touch
    // the binding in hyprland.lua - today it opens pause straight into the
    // Arsenal grid, i.e. the same thing that was under SUPER+R: programs.
    // You can start typing a program name right away.
    GlobalShortcut {
        appid: "quickshell"
        name: "menuToggle"
        description: "Open or close the tile menu (pause)"

        onPressed: {
            if (!root.pauzaOpen) kafle.wejdz("uzbrojenie");
            root.pauzaOpen = !root.pauzaOpen;
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "mediaToggle"
        description: "Open or close the media panel"

        onPressed: root.mediaOpen = !root.mediaOpen
    }

    // SUPER+B - next power profile (see przelaczProfil above).
    GlobalShortcut {
        appid: "quickshell"
        name: "profilZasilania"
        description: "Switch to the next power profile"

        onPressed: root.przelaczProfil()
    }
}
