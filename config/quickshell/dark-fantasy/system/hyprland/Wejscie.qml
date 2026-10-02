// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  HYPRLAND -> INPUT - touchpad, scrolling direction, keyboard layout,
//  floor gestures and their direction.
//
//  Touchpad sensitivity is a device rule (hl.device with the touchpad name
//  from "hyprctl devices"), not input:sensitivity - that one would also
//  change the mouse and the TrackPoint. Without a touchpad the row is dimmed.
//
//  Floor gestures are disabled by floors.ustaw({ gesty = false }): the gesture stays
//  registered but does nothing - hl.gesture has no handle that
//  could remove it.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs
import qs.components
import qs.services
import qs.system

SekcjaOpcji {
    id: root

    readonly property var uklady: UstawieniaHyprlanda.ukladyKlawiatury

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Touchpad sensitivity", "Czułość touchpada")
        typ: "suwak"; od: -1; doo: 1; krok: 0.1
        dostepny: UstawieniaHyprlanda.nazwaTouchpada !== ""
        wartosc: UstawieniaHyprlanda.czuloscTouchpada
        formatuj: v => (v > 0 ? "+" : "") + Tr.dziesietna(v, 1)
        onZmieniono: function (v) { UstawieniaHyprlanda.ustawCzuloscTouchpada(v); }
    }

    // Scrolling direction of pages, separately for the touchpad and the
    // mouse wheel: "natural" means the content follows the fingers, like on
    // a phone - two fingers up move the page up, i.e. scroll down.
    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Natural scrolling (touchpad)", "Naturalne przewijanie (touchpad)")
        typ: "przelacznik"
        wlaczony: UstawieniaHyprlanda.wartosci["input:touchpad:natural_scroll"] ?? false
        onZmieniono: function (v) { UstawieniaHyprlanda.ustaw("input:touchpad:natural_scroll", v); }
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Natural scrolling (mouse wheel)", "Naturalne przewijanie (kółko myszy)")
        typ: "przelacznik"
        wlaczony: UstawieniaHyprlanda.wartosci["input:natural_scroll"] ?? false
        onZmieniono: function (v) { UstawieniaHyprlanda.ustaw("input:natural_scroll", v); }
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Keyboard layout", "Układ klawiatury")
        typ: "wybor"
        // A layout list from the config (e.g. "pl,us", switched with a key)
        // is not one of the single layouts below. It is shown as its own,
        // first option - before, the row showed the first layout and one
        // arrow press replaced the list with a single layout.
        readonly property string obecny: UstawieniaHyprlanda.wartosci["input:kb_layout"] ?? ""
        readonly property var lista: obecny !== "" && !root.uklady.some(u => u.kod === obecny)
            ? [{ kod: obecny, nazwa: obecny.split(",").map(k => k.trim()).join(", ") }].concat(root.uklady)
            : root.uklady
        opcje: lista.map(u => ({ kod: u.kod, nazwa: u.nazwa }))
        indeks: Math.max(0, lista.findIndex(u => u.kod === obecny))
        onZmieniono: function (i) {
            if (lista[i].kod !== obecny) UstawieniaHyprlanda.ustaw("input:kb_layout", lista[i].kod);
        }
    }

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("Floor gestures (3 fingers)", "Gesty pięter (3 palce)")
        typ: "przelacznik"
        wlaczony: UstawieniaHyprlanda.stan.gesty
        onZmieniono: function (v) { UstawieniaHyprlanda.ustawGesty(v); }
    }

    // Direction of the 3-finger gestures: gestures:workspace_swipe_invert,
    // which floors.lua reads when the fingers lift (the desktop and the
    // floor gesture alike). true = Hyprland's default.
    WierszOpcji {
        width: root.width
        // Short values - the value field is 170 px wide.
        etykieta: Tr.t("Next desktop / floor: fingers", "Następny pulpit / piętro: palce")
        typ: "wybor"
        dostepny: UstawieniaHyprlanda.stan.gesty
        readonly property bool odwrocone: UstawieniaHyprlanda.wartosci["gestures:workspace_swipe_invert"] ?? true
        opcje: [
            { kod: true,  nazwa: Tr.t("left / up", "w lewo / w górę") },
            { kod: false, nazwa: Tr.t("right / down", "w prawo / w dół") }
        ]
        indeks: odwrocone ? 0 : 1
        onZmieniono: function (i) {
            UstawieniaHyprlanda.ustaw("gestures:workspace_swipe_invert", i === 0);
        }
    }
}
