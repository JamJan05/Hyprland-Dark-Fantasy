pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT - see Brightness.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  CPU POWER LIMIT - a hard ceiling in watts for each power profile.
//
//  E.g. power saver 7 W, balanced 15 W, performance factory. The value
//  for each profile is kept in UstawieniaPowloki (powloka.json), 0 means
//  the factory limit. The shell does not talk to the CPU itself: it calls
//  /usr/local/sbin/df-limit-mocy through "sudo -n", and that script calls
//  ryzenadj - rationale and the sudoers rule in the script's header.
//
//  WHEN IT IS APPLIED:
//    - on a power profile change (Cogwheel, SUPER+B, anything else talking
//      to power-profiles-daemon) and on a limit change in Cogwheel - after
//      800 ms of quiet, so dragging the slider is one call, not twenty;
//    - once a minute, because some firmware quietly restores its own limits
//      on charger plug-in or resume. The script only reads when nothing
//      changed.
//
//  "sudo -n" never asks for a password: without the sudoers rule it fails,
//  and Cogwheel shows what is missing instead of a password dialog every minute.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property string skrypt: "/usr/local/sbin/df-limit-mocy"

    // The script answered at least once - the rows show in Cogwheel.
    property bool obslugiwany: false
    // The script is installed at all. Without it the rows hide entirely.
    property bool zainstalowany: false
    property string blad: ""

    // Current sustained limit (STAPM) and the factory one of the CURRENT
    // platform profile, W. On a ThinkPad the firmware has its own limit
    // per profile - see the df-limit-mocy header.
    property real obecny: 0
    property real fabryczny: 0

    // Highest limit a slider in Cogwheel can set: the top of the Ryzen 7 250's
    // configurable TDP. One step above it on the slider means "factory".
    readonly property int maksimum: 30

    // What the current profile wants; 0 = factory.
    readonly property int docelowy: UstawieniaPowloki.limitMocy(PowerProfiles.profile)

    onDocelowyChanged: opoznienie.restart()

    function zastosuj(): void {
        uruchom([docelowy > 0 ? String(docelowy) : "fabryczny"]);
    }

    // One process at a time; a request during a call waits for its end.
    property bool ponownie: false

    function uruchom(argumenty: var): void {
        if (proces.running) {
            ponownie = true;
            return;
        }
        proces.command = ["sudo", "-n", skrypt].concat(argumenty);
        proces.running = true;
    }

    Timer {
        id: opoznienie
        interval: 800
        onTriggered: root.zastosuj()
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.obslugiwany
        onTriggered: root.zastosuj()
    }

    Process {
        id: proces
        stdout: StdioCollector { id: wyjscie }
        stderr: StdioCollector { id: bledy }
        onExited: function (kod) {
            // "stapm fast slow fstapm ffast fslow"
            const c = wyjscie.text.trim().split(/\s+/);
            if (kod === 0 && c.length >= 6) {
                root.obslugiwany = true;
                root.zainstalowany = true;
                root.obecny = Number(c[0]);
                root.fabryczny = Number(c[3]);
                root.blad = "";
            } else {
                // sudo -n without the rule (or without the script) returns 1 with
                // a message from sudo - the setup is absent, the rows stay hidden.
                root.zainstalowany = kod !== 1 || !bledy.text.includes("sudo");
                root.blad = kod === 4
                    ? Tr.t("No access to the CPU - the iomem=relaxed kernel parameter is missing.",
                           "Brak dostępu do procesora - brakuje parametru jądra iomem=relaxed.")
                    : kod === 2
                    ? Tr.t("ryzenadj is not installed in /usr/local/bin.",
                           "ryzenadj nie jest zainstalowany w /usr/local/bin.")
                    : (bledy.text.trim() || Tr.t("Could not set the power limit.",
                                                 "Nie udało się ustawić limitu mocy."));
            }
            if (root.ponownie) {
                root.ponownie = false;
                root.zastosuj();
            }
        }
    }
}
