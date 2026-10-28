// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  HYPRLAND -> APPEARANCE - gaps, border, blur, inactive windows.
//
//  Each row reads the current value from services/UstawieniaHyprlanda.qml
//  (hyprctl getoption) and on change calls ustaw() - the change goes
//  straight to Hyprland and shortly after to ~/.config/hypr/ustawienia.lua.
//  Slider ranges are chosen so the extremes are still usable:
//  a 60 px gap already eats a quarter of a laptop screen.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs
import qs.components
import qs.services
import qs.system

SekcjaOpcji {
    id: root

    readonly property var w: UstawieniaHyprlanda.wartosci
    readonly property var px: v => Math.round(v) + " px"
    readonly property var procent: v => Math.round(v * 100) + " %"

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Gap between windows", "Odstęp między oknami")
        typ: "suwak"; od: 0; doo: 30; krok: 1
        wartosc: root.w["general:gaps_in"] ?? 6
        formatuj: root.px
        onZmieniono: function (v) { UstawieniaHyprlanda.ustaw("general:gaps_in", v); }
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Gap from screen edge", "Odstęp od krawędzi")
        typ: "suwak"; od: 0; doo: 60; krok: 2
        wartosc: root.w["general:gaps_out"] ?? 12
        formatuj: root.px
        onZmieniono: function (v) { UstawieniaHyprlanda.ustaw("general:gaps_out", v); }
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Border width", "Grubość ramki")
        typ: "suwak"; od: 0; doo: 6; krok: 1
        wartosc: root.w["general:border_size"] ?? 1
        formatuj: root.px
        onZmieniono: function (v) { UstawieniaHyprlanda.ustaw("general:border_size", v); }
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Blur", "Rozmycie")
        typ: "przelacznik"
        wlaczony: root.w["decoration:blur:enabled"] ?? true
        onZmieniono: function (v) { UstawieniaHyprlanda.ustaw("decoration:blur:enabled", v); }
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Blur strength", "Siła rozmycia")
        typ: "suwak"; od: 1; doo: 20; krok: 1
        dostepny: root.w["decoration:blur:enabled"] ?? true
        wartosc: root.w["decoration:blur:size"] ?? 6
        formatuj: v => String(Math.round(v))
        onZmieniono: function (v) { UstawieniaHyprlanda.ustaw("decoration:blur:size", v); }
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Opacity of inactive windows", "Krycie nieaktywnych okien")
        typ: "suwak"; od: 0.5; doo: 1; krok: 0.02
        wartosc: root.w["decoration:inactive_opacity"] ?? 1.0
        formatuj: root.procent
        onZmieniono: function (v) { UstawieniaHyprlanda.ustaw("decoration:inactive_opacity", v); }
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Dim inactive windows", "Przygaszanie nieaktywnych")
        typ: "przelacznik"
        wlaczony: root.w["decoration:dim_inactive"] ?? true
        onZmieniono: function (v) { UstawieniaHyprlanda.ustaw("decoration:dim_inactive", v); }
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Dimming strength", "Siła przygaszania")
        typ: "suwak"; od: 0; doo: 0.6; krok: 0.05
        dostepny: root.w["decoration:dim_inactive"] ?? true
        wartosc: root.w["decoration:dim_strength"] ?? 0.1
        formatuj: root.procent
        onZmieniono: function (v) { UstawieniaHyprlanda.ustaw("decoration:dim_strength", v); }
    }
}
