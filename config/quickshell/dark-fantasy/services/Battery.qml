pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT - see Brightness.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  BATTERY - level, health and charging for the HP bar.
//
//  Three numbers from /sys/class/power_supply/<battery>/:
//      *_now          how much there is now     -> bar fill
//      *_full         how much it holds today   -> visible bar length
//      *_full_design  how much it held when new -> length scale (px per Wh)
//  A worn battery has "full" smaller than "design", so its HP bar
//  is shorter - like the max HP of a character who has lost their humanity.
//
//  Batteries report in energy (energy_*, µWh) or in charge (charge_*,
//  µAh). For charge we convert to Wh using the design voltage
//  (voltage_min_design) - the length scale must be in the same units
//  on every laptop.
//
//  ---------------------------------------------------------------
//  READ EVERY 10 S, NOT watchChanges AS IN Brightness.qml
//
//  That was the plan, and it was tested: FileView with watchChanges on
//  energy_now and capacity got NOT A SINGLE event in 150 s,
//  even though energy_now dropped from 62.08 to 61.59 Wh in that time. The backlight
//  reports changes (the driver calls sysfs_notify), the battery does not - the kernel
//  announces its changes only via uevent, which inotify does not see.
//
//  A read every 10 s is three small files, no processes. So that plugging in
//  the charger does not wait for the next read, we reload the state immediately
//  when UPower reports a change over D-Bus (the same service that
//  the Power section in the Cogwheel uses).
//
//  The battery directory is searched ONCE, with one process - QML cannot list
//  /sys/class/power_supply. Device batteries (mice,
//  headphones) are skipped: they have scope "Device".
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    // E.g. "/sys/class/power_supply/BAT0". Empty = computer without a battery.
    property string katalog: ""

    // "energy" or "charge" - see the header.
    property string prefiks: "energy"

    readonly property bool obecna: katalog !== ""

    property real teraz: 0
    property real pelna: 0
    property real projekt: 0
    property real napiecie: 0      // µV, only with charge_*
    property string status: ""

    // Level 0.0 - 1.0 relative to today's capacity.
    readonly property real poziom: pelna > 0 ? Math.min(1, teraz / pelna) : 0

    // Health 0.0 - 1.0: today's capacity versus the design capacity. This laptop's
    // battery reports "full" LARGER than "design" (66.6 vs 64 Wh)
    // - a new battery cannot have more than 100 % health.
    readonly property real kondycja: projekt > 0 ? Math.min(1, pelna / projekt) : 1

    // Design capacity in Wh - the HP bar length scale.
    readonly property real projektWh: {
        if (prefiks === "energy") return projekt / 1e6;
        // µAh * V = µWh; without a voltage we assume a typical 11.1 V (3 cells).
        const wolty = napiecie > 0 ? napiecie / 1e6 : 11.1;
        return projekt / 1e6 * wolty;
    }

    readonly property bool laduje: status === "Charging"
    readonly property bool naKablu: status === "Full" || status === "Not charging"
    readonly property bool naBaterii: obecna && status === "Discharging"

    // How long the battery will last, in seconds; 0 = unknown or not on battery.
    // From UPower, not from sysfs: power_now jumps with every load spike,
    // and UPower averages it - a raw teraz / power_now would flicker
    // between "40 min" and "6 h".
    readonly property real pozostalo: naBaterii && UPower.displayDevice
        ? Math.max(0, UPower.displayDevice.timeToEmpty)
        : 0

    // "3 h 42 min" / "25 min".
    function czas(sekundy: real): string {
        const minuty = Math.round(sekundy / 60);
        const h = Math.floor(minuty / 60);
        return h <= 0 ? minuty + " min" : h + " h " + minuty % 60 + " min";
    }

    function odswiez(): void {
        if (!obecna) return;
        plikTeraz.reload();
        plikPelna.reload();
        plikStatus.reload();
    }

    function liczba(tekst: string): real {
        const n = Number(tekst.trim());
        return isNaN(n) ? 0 : n;
    }

    Process {
        running: true
        command: ["sh", "-c",
            "for d in /sys/class/power_supply/*; do " +
            "test \"$(cat \"$d/type\" 2>/dev/null)\" = Battery || continue; " +
            "test \"$(cat \"$d/scope\" 2>/dev/null)\" = Device && continue; " +
            "if test -r \"$d/energy_full_design\"; then echo \"$d energy\"; exit 0; fi; " +
            "if test -r \"$d/charge_full_design\"; then echo \"$d charge\"; exit 0; fi; " +
            "done"]
        stdout: StdioCollector { id: wykrycie }
        onExited: {
            const czesci = wykrycie.text.trim().split(" ");
            if (czesci.length !== 2) return;
            root.prefiks = czesci[1];
            root.katalog = czesci[0];
        }
    }

    FileView {
        id: plikTeraz
        path: root.obecna ? root.katalog + "/" + root.prefiks + "_now" : ""
        onLoaded: root.teraz = root.liczba(text())
    }

    FileView {
        id: plikPelna
        path: root.obecna ? root.katalog + "/" + root.prefiks + "_full" : ""
        onLoaded: root.pelna = root.liczba(text())
    }

    // Design capacity and voltage do not change - read once.
    FileView {
        path: root.obecna ? root.katalog + "/" + root.prefiks + "_full_design" : ""
        onLoaded: root.projekt = root.liczba(text())
    }

    FileView {
        path: root.obecna && root.prefiks === "charge" ? root.katalog + "/voltage_min_design" : ""
        onLoaded: root.napiecie = root.liczba(text())
    }

    FileView {
        id: plikStatus
        path: root.obecna ? root.katalog + "/status" : ""
        onLoaded: root.status = text().trim()
    }

    Timer {
        interval: 10000
        repeat: true
        running: root.obecna
        onTriggered: root.odswiez()
    }

    // UPower events only as a trigger for re-reading - the numbers
    // come from sysfs anyway, so that all three come from the same source.
    Connections {
        target: UPower.displayDevice
        ignoreUnknownSignals: true

        function onStateChanged() { root.odswiez(); }
        function onPercentageChanged() { root.odswiez(); }
    }
}
