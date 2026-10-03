pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT - see Brightness.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  BATTERY CHARGE LIMIT - the threshold at which the battery stops charging.
//
//  The kernel exposes it in /sys/class/power_supply/BAT0/ as
//  charge_control_end_threshold (end) and charge_control_start_threshold
//  (the percentage at which charging starts again); on a ThinkPad this is done by
//  the thinkpad_acpi driver. The shell does not write to sysfs itself, it calls
//  local/bin/limit-ladowania instead, because the script:
//    - knows the write order (the kernel rejects an end lower than the start),
//    - elevates itself via pkexec (password dialog) when it lacks write permission,
//    - also works from a terminal, without the shell.
//
//  One slider instead of two: start = limit - 5 (rationale in the script).
//
//  MEMORY. The chosen limit goes into UstawieniaPowloki (powloka.json)
//  and comes back at shell startup - but only silently (LIMIT_BEZ_PKEXEC),
//  i.e. when a udev rule grants write permission. The ThinkPad keeps the thresholds
//  in the controller anyway, so without the rule nothing is lost after a reboot.
//
//  SYSFS EMITS NO EVENTS (pitfall described in Battery.qml), so the thresholds
//  are read when the Power section is opened and after every write.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQml
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string skrypt: Quickshell.env("HOME") + "/.local/bin/limit-ladowania"

    // The battery has threshold files. Without them the row in the Cogwheel hides.
    property bool obslugiwany: false
    // Writing without a password - udev rule installed.
    property bool zapisywalny: false
    property int start: -1
    property int koniec: 100

    // Slider value waiting to be written. -1 = nothing is waiting.
    property int roboczy: -1
    readonly property int limit: roboczy >= 0 ? roboczy : koniec

    property bool zapisuje: false
    property string blad: ""

    function odswiez(): void {
        if (!odczyt.running) odczyt.running = true;
    }

    Process {
        id: odczyt
        command: [root.skrypt]
        stdout: StdioCollector { id: wyjscieOdczytu }
        onExited: function (kod) {
            // "start end writable", e.g. "70 75 1".
            const c = wyjscieOdczytu.text.trim().split(/\s+/);
            root.obslugiwany = kod === 0 && c.length >= 3;
            if (!root.obslugiwany) return;
            root.start = c[0] === "-" ? -1 : parseInt(c[0], 10);
            root.koniec = parseInt(c[1], 10);
            root.zapisywalny = c[2] === "1";
        }
    }

    // The slider writes only after a moment of quiet: every step is a process, and without
    // the udev rule - a password dialog.
    function ustaw(n: int): void {
        roboczy = Math.max(50, Math.min(100, Math.round(n / 5) * 5));
        blad = "";
        opoznienie.restart();
    }

    Timer {
        id: opoznienie
        interval: 800
        onTriggered: root.zapisz(root.roboczy, false)
    }

    property int zapisywany: -1
    property bool zapisCichy: false

    function zapisz(n: int, cicho: bool): void {
        // Write in progress - the next value will be picked up by onExited below.
        if (zapis.running) return;
        zapisywany = n;
        zapisCichy = cicho;
        zapis.command = cicho
            ? ["env", "LIMIT_BEZ_PKEXEC=1", skrypt, String(n)]
            : [skrypt, String(n)];
        zapisuje = true;
        zapis.running = true;
    }

    Process {
        id: zapis
        stderr: StdioCollector { id: bledyZapisu }
        onExited: function (kod) {
            root.zapisuje = false;
            if (kod === 0) {
                UstawieniaPowloki.ustawLimitLadowania(root.zapisywany);
                root.blad = "";
            } else if (!root.zapisCichy) {
                // 126 and 127 are returned by pkexec: dialog closed or authorization denied.
                root.blad = kod === 126 || kod === 127
                    ? Tr.t("Save cancelled - limit unchanged.", "Zapis anulowany - limit bez zmian.")
                    : (bledyZapisu.text.trim() || Tr.t("Could not save the limit.", "Nie udało się zapisać limitu."));
            }
            // The slider moved during the write - we write that value too,
            // also after a failed or cancelled write: the newer value is a
            // new request, and dropping it left the slider snapping back
            // with that value never tried.
            if (root.roboczy >= 0 && root.roboczy !== root.zapisywany)
                opoznienie.restart();
            else
                root.roboczy = -1;
            root.odswiez();
        }
    }

    // RESTORE AT STARTUP - see "MEMORY" in the header. After 3 s, because
    // powloka.json and the threshold read arrive asynchronously.
    Timer {
        interval: 3000
        running: true
        onTriggered: {
            const zapamietany = UstawieniaPowloki.limitLadowania;
            if (root.obslugiwany && root.zapisywalny && zapamietany >= 50
                    && zapamietany !== root.koniec)
                root.zapisz(zapamietany, true);
        }
    }

    Component.onCompleted: odswiez()
}
