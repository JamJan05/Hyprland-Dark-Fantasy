pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT - see Brightness.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  BLUETOOTH MEMORY - on or off, the way it was left.
//
//  BlueZ does not remember it: with AutoEnable (the default in
//  /etc/bluetooth/main.conf) every adapter comes up powered after a boot,
//  and OpenRC has no systemd-rfkill that would restore a switched-off radio.
//  So the shell keeps the state in UstawieniaPowloki (powloka.json) and
//  applies it at startup.
//
//  Every change counts, not only the Cogwheel toggle - also bluetoothctl or
//  the bar - because the state is followed through the adapter's "enabled".
//
//  TWO PITFALLS.
//    - At startup the adapter may still be missing (bluetoothd starts in
//      parallel) or report the AutoEnable state for a moment, and
//      powloka.json loads asynchronously. So nothing is saved until the
//      saved state has been applied - after the file has loaded, and again
//      for a replacement adapter - otherwise that first "on" would overwrite
//      a saved "off".
//    - At shutdown bluetoothd may stop before the session and the adapter may
//      report "off" on its way out. So a change seen on the adapter is saved
//      only after it has held for ZWLOKA ms with the adapter still present.
//      The Cogwheel toggle goes through ustaw() and is saved at once, so
//      logging out right after it does not lose it.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQml
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property int zwloka: 3000

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool wlaczony: adapter ? adapter.enabled : false

    // The saved state has been applied (or there was nothing to apply) -
    // from now on changes are saved.
    property bool gotowe: false

    // powloka.json is read asynchronously - see the timer below.
    property bool czasMinal: false

    // Called by shell.qml, only to create the singleton at session start.
    function start(): void {}

    // The Cogwheel's power toggle: a deliberate change, saved immediately.
    function ustaw(wl: bool): void {
        if (!adapter) return;
        zapis.stop();
        adapter.enabled = wl;
        if (gotowe) UstawieniaPowloki.ustawBluetooth(wl);
    }

    function przywroc(): void {
        if (gotowe || !czasMinal || !adapter || !UstawieniaPowloki.wczytane) return;
        const zapisany = UstawieniaPowloki.bluetooth;
        if (zapisany !== -1 && adapter.enabled !== (zapisany === 1))
            adapter.enabled = zapisany === 1;
        gotowe = true;
    }

    // After 3 s, like the charge limit (services/Ladowanie.qml): powloka.json
    // and the BlueZ adapter both arrive asynchronously.
    Timer {
        interval: 3000
        running: true
        onTriggered: {
            root.czasMinal = true;
            root.przywroc();
        }
    }

    // bluetoothd started later than the shell, or the adapter was replaced
    // (bluetoothd restarted, a USB dongle): the new one gets the saved state
    // too, and a pending save belonging to the old one is dropped.
    onAdapterChanged: {
        zapis.stop();
        gotowe = false;
        przywroc();
    }

    readonly property bool ustawieniaWczytane: UstawieniaPowloki.wczytane
    onUstawieniaWczytaneChanged: przywroc()

    onWlaczonyChanged: if (gotowe) zapis.restart()

    Timer {
        id: zapis
        interval: root.zwloka
        onTriggered: {
            if (root.adapter) UstawieniaPowloki.ustawBluetooth(root.adapter.enabled);
        }
    }
}
