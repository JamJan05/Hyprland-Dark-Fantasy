pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT - see Brightness.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  SHELL SETTINGS - what is toggled within the shell itself
//  and has to survive its restart.
//
//  Two things:
//    hudBars         - whether the HUD shows the stat bars (Theme.hudBars is
//                      the default value for a fresh install). Toggled by
//                      the Cogwheel or "qs ipc call hud przelaczPaski".
//    limitLadowania  - the last battery charge limit chosen in the Cogwheel,
//                      restored at startup (services/Ladowanie.qml).
//                      0 = never set, nothing is restored.
//    moc*            - CPU power limit in W for each power profile
//                      (services/LimitMocy.qml). 0 = factory limit.
//    dnd             - "do not disturb" in Tidings (services/Notifications.qml).
//    bluetooth       - whether Bluetooth was on (services/PamiecBluetooth.qml).
//                      -1 = never saved, nothing is restored.
//
//  ---------------------------------------------------------------
//  WHY ~/.local/state AND NOT THE REPOSITORY
//
//  This is the state of this computer, not desktop configuration - just like
//  clipboard history. In the repo every click of a toggle would be a change
//  in git. Directory per XDG: $XDG_STATE_HOME or ~/.local/state.
//  The path is explicit rather than Quickshell.statePath(): that one depends on
//  the configuration identifier, i.e. on the path the shell started from,
//  so the test stand and the live shell would have two different files.
//
//  Writing via JsonAdapter: a property change in QML triggers
//  adapterUpdated, which writes the file (FileView creates missing
//  directories itself). A missing file on first run is not an error -
//  the default values remain.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs

Singleton {
    id: root

    readonly property bool hudBars: dane.hudBars

    function ustawPaski(wlaczone: bool): void {
        dane.hudBars = wlaczone;
    }

    function przelaczPaski(): void {
        dane.hudBars = !dane.hudBars;
    }

    readonly property int limitLadowania: dane.limitLadowania

    function ustawLimitLadowania(procent: int): void {
        dane.limitLadowania = procent;
    }

    function limitMocy(profil: int): int {
        switch (profil) {
        case PowerProfile.PowerSaver:  return dane.mocOszczedny;
        case PowerProfile.Balanced:    return dane.mocZrownowazony;
        case PowerProfile.Performance: return dane.mocWydajny;
        }
        return 0;
    }

    function ustawLimitMocy(profil: int, waty: int): void {
        switch (profil) {
        case PowerProfile.PowerSaver:  dane.mocOszczedny = waty; break;
        case PowerProfile.Balanced:    dane.mocZrownowazony = waty; break;
        case PowerProfile.Performance: dane.mocWydajny = waty; break;
        }
    }

    // powloka.json has been read (or does not exist yet) - FileView loads
    // asynchronously, and until then every property holds its default.
    property bool wczytane: false

    readonly property bool dnd: dane.dnd

    function ustawDnd(wlaczone: bool): void {
        dane.dnd = wlaczone;
    }

    readonly property int bluetooth: dane.bluetooth

    function ustawBluetooth(wlaczony: bool): void {
        dane.bluetooth = wlaczony ? 1 : 0;
    }

    // Interface language: "en" (default) or "pl". Read through Tr.
    readonly property string jezyk: dane.jezyk

    function ustawJezyk(kod: string): void {
        const nowy = kod === "pl" ? "pl" : "en";
        if (nowy === dane.jezyk) return;
        dane.jezyk = nowy;
        JezykZewnetrzny.zmieniono();
    }

    readonly property string sciezka: {
        const stan = Quickshell.env("XDG_STATE_HOME");
        const baza = stan ? stan : Quickshell.env("HOME") + "/.local/state";
        return baza + "/dark-fantasy/powloka.json";
    }

    FileView {
        path: root.sciezka
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.wczytane = true
        onLoadFailed: root.wczytane = true

        adapter: JsonAdapter {
            id: dane
            property bool hudBars: Theme.hudBars
            property int limitLadowania: 0
            property int mocOszczedny: 0
            property int mocZrownowazony: 0
            property int mocWydajny: 0
            property string jezyk: "en"
            property bool dnd: false
            property int bluetooth: -1
        }
    }
}
