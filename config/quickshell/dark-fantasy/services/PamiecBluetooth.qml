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

    // A Cogwheel toggle made before the saved state was applied (1 / 0),
    // -1 = none. It wins over the saved state instead of being undone by it.
    property int wyborUzytkownika: -1

    // The Cogwheel's power toggle: a deliberate change, saved immediately -
    // or, before the saved state has been applied, remembered and saved then.
    function ustaw(wl: bool): void {
        if (!adapter) return;
        zapis.stop();
        adapter.enabled = wl;
        if (gotowe) UstawieniaPowloki.ustawBluetooth(wl);
        else wyborUzytkownika = wl ? 1 : 0;
    }

    function przywroc(): void {
        if (gotowe || !czasMinal || !adapter || !UstawieniaPowloki.wczytane) return;
        if (wyborUzytkownika !== -1) {
            adapter.enabled = wyborUzytkownika === 1;
            UstawieniaPowloki.ustawBluetooth(wyborUzytkownika === 1);
            wyborUzytkownika = -1;
        } else {
            const zapisany = UstawieniaPowloki.bluetooth;
            if (zapisany !== -1 && adapter.enabled !== (zapisany === 1))
                adapter.enabled = zapisany === 1;
        }
        gotowe = true;
    }

    // ---------------------------------------------------------------
    //  PAIRING WITH TEMPORARY TRUST
    //
    //  The pairing agent (local/bin/df-agent-bt) accepts only devices marked
    //  Trusted, so a device is marked trusted right before pair(). BlueZ does
    //  not clear Trusted when pairing fails, and a trusted device would then
    //  get past the agent later without anyone clicking anything. So trust
    //  set HERE is taken back when the pairing ends without a pairing; trust
    //  the device already had stays. Kept in this singleton, not in the list
    //  row, because the row goes away when the Cogwheel closes mid-pairing.
    // ---------------------------------------------------------------
    property var parowane: null
    property bool zaufanieTymczasowe: false

    function paruj(urzadzenie: var): void {
        if (!urzadzenie) return;
        zakonczParowanie();
        parowane = urzadzenie;
        zaufanieTymczasowe = !urzadzenie.trusted;
        if (zaufanieTymczasowe) urzadzenie.trusted = true;
        urzadzenie.pair();
        straznikParowania.restart();
    }

    function zakonczParowanie(): void {
        const u = parowane;
        const tymczasowe = zaufanieTymczasowe;
        parowane = null;
        zaufanieTymczasowe = false;
        straznikParowania.stop();
        sprawdzenieParowania.stop();
        if (!u || !tymczasowe) return;
        try {
            if (!u.paired && !u.bonded) u.trusted = false;
        } catch (e) {
            // The device object is gone (BlueZ dropped a temporary device) -
            // and its trust went with it.
        }
    }

    readonly property bool paruje: parowane ? parowane.pairing : false

    // The pairing ended; "paired" may arrive a moment after "pairing" drops,
    // so the result is checked 2 s later.
    onParujeChanged: if (!paruje && parowane) sprawdzenieParowania.restart()

    Timer {
        id: sprawdzenieParowania
        interval: 2000
        onTriggered: root.zakonczParowanie()
    }

    // A pairing that never started or never ended.
    Timer {
        id: straznikParowania
        interval: 60000
        onTriggered: root.zakonczParowanie()
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
