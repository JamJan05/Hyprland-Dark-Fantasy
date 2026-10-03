// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  HYPRLAND -> MONITOR - scale, refresh rate, second monitor.
//
//  Scale only from the list of "clean" scales for the current resolution -
//  the resolution divided by the scale must give an integer, otherwise
//  Hyprland silently picks a different one (comment at hl.monitor in hyprland.lua).
//  The list is computed by services/UstawieniaHyprlanda.qml from "hyprctl monitors".
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs
import qs.components
import qs.services
import qs.system

SekcjaOpcji {
    id: root

    readonly property var m: UstawieniaHyprlanda.monitor
    readonly property var skale: UstawieniaHyprlanda.skale
    readonly property var hz: UstawieniaHyprlanda.odswiezania

    // The saved scale only when it was saved for this same output
    // (see stanMonitora in UstawieniaHyprlanda).
    readonly property real skala: m && UstawieniaHyprlanda.stan.monitor
            && UstawieniaHyprlanda.stan.monitor.nazwa === m.name
        ? Number(UstawieniaHyprlanda.stan.monitor.skala) : (m ? m.scale : 1)

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Monitor", "Monitor")
        typ: "info"
        tekst: root.m ? root.m.name + "  " + root.m.width + "×" + root.m.height : "-"
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Scale", "Skala")
        typ: "wybor"
        opcje: root.skale.map(s => ({ kod: s, nazwa: (Tr.pl ? String(s).replace(".", ",") : String(s)) + "×" }))
        indeks: Math.max(0, root.skale.findIndex(s => Math.abs(s - root.skala) < 0.001))
        dostepny: root.skale.length > 0
        onZmieniono: function (i) { UstawieniaHyprlanda.ustawSkale(root.skale[i]); }
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Refresh rate", "Odświeżanie")
        typ: "wybor"
        opcje: root.hz.map(h => ({ kod: h, nazwa: Tr.dziesietna(h, 2) + " Hz" }))
        indeks: Math.max(0, root.hz.findIndex(h => root.m && Math.abs(h - root.m.refreshRate) < 0.05))
        dostepny: root.hz.length > 1
        onZmieniono: function (i) { UstawieniaHyprlanda.ustawOdswiezanie(root.hz[i]); }
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Second monitor", "Drugi monitor")
            + (UstawieniaHyprlanda.drugi ? " (" + UstawieniaHyprlanda.drugi.name + ")" : "")
        typ: UstawieniaHyprlanda.drugi ? "wybor" : "info"
        tekst: Tr.t("not connected", "nie podłączony")
        opcje: UstawieniaHyprlanda.pozycjeDrugiego
        indeks: {
            const d = UstawieniaHyprlanda.stan.drugiMonitor;
            return d ? Math.max(0, UstawieniaHyprlanda.pozycjeDrugiego.findIndex(p => p.kod === d.pozycja)) : 0;
        }
        onZmieniono: function (i) { UstawieniaHyprlanda.ustawPozycjeDrugiego(UstawieniaHyprlanda.pozycjeDrugiego[i].kod); }
    }
}
