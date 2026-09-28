// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  HYPRLAND -> SHORTCUTS.
//
//  Three groups (details at "SHORTCUTS" in services/UstawieniaHyprlanda.qml
//  and "EDITABLE SHORTCUTS" in hyprland.lua):
//
//    Applications  shortcuts added here - Enter: new keys, Delete: remove
//    Shortcuts     the ones registered with skrot() - Enter: new keys,
//                  Delete: back to the default keys (marked "*" when moved)
//    Fixed         desktops, mouse, media keys - view only
//
//  New keys are captured from the keyboard (WierszOpcji, typ "skrot").
//  While a row waits for them, Hyprland sits in the empty "df-przechwyt"
//  submap, so the pressed combination reaches the shell instead of firing
//  whatever is bound to it. Rejected: keys taken by another bind, and keys
//  without SUPER, CTRL or ALT (they would stop working for typing).
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.components
import qs.services
import qs.system

SekcjaOpcji {
    id: root

    // ---- adding an application shortcut ----
    property bool dodawanie: false
    property string fraza: ""
    property int indeksAplikacji: 0
    property string noweKlawisze: ""

    property string blad: ""

    readonly property var aplikacje: {
        const q = fraza.trim().toLowerCase();
        const l = DesktopEntries.applications.values.filter(e => !e.noDisplay
            && UstawieniaHyprlanda.komendaAplikacji(e) !== ""
            && (q === "" || e.name.toLowerCase().indexOf(q) !== -1 || e.id.toLowerCase().indexOf(q) !== -1));
        l.sort((a, b) => a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1);
        return l;
    }

    readonly property var aplikacja:
        indeksAplikacji >= 0 && indeksAplikacji < aplikacje.length ? aplikacje[indeksAplikacji] : null

    function zacznijDodawanie(): void {
        fraza = "";
        indeksAplikacji = 0;
        noweKlawisze = "";
        blad = "";
        dodawanie = true;
    }

    function zakonczDodawanie(): void {
        dodawanie = false;
        wybrany = 0;
    }

    // Checks new keys; on a problem shows it and returns false.
    function sprawdz(klawisze: string, pomin: string): bool {
        if (!UstawieniaHyprlanda.bezpieczny(klawisze)) {
            blad = Tr.t("Add SUPER, CTRL or ALT - a key on its own would stop working for typing.",
                        "Dodaj SUPER, CTRL albo ALT - sam klawisz przestałby działać przy pisaniu.");
            return false;
        }
        const zajety = UstawieniaHyprlanda.kolizja(klawisze, pomin);
        if (zajety !== "") {
            blad = Tr.t("%1 is already taken: %2", "%1 jest już zajęte: %2")
                .arg(UstawieniaHyprlanda.ladnie(klawisze)).arg(zajety);
            return false;
        }
        blad = "";
        return true;
    }

    // Hyprland stays in the capture submap while ANY row waits for keys -
    // switching rows by mouse must not drop it halfway.
    function aktualizujPrzechwytywanie(): void {
        UstawieniaHyprlanda.przechwytuj(wiersze.some(w => w.typ === "skrot" && w.edycja));
    }

    function przerwijPrzechwytywanie(): void {
        for (const w of wiersze) if (w.typ === "skrot") w.edycja = false;
        UstawieniaHyprlanda.przechwytuj(false);
    }

    onVisibleChanged: if (!visible) { przerwijPrzechwytywanie(); dodawanie = false; }

    // A separate Connections, not onAktywnaChanged: SekcjaOpcji already
    // handles that signal itself.
    Connections {
        target: root
        function onAktywnaChanged(): void {
            if (!root.aktywna) root.przerwijPrzechwytywanie();
        }
    }

    Component.onDestruction: UstawieniaHyprlanda.przechwytuj(false)

    Label {
        width: root.width
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        color: Theme.textMuted
        bottomPadding: Theme.spacingSm
        text: Tr.t("Enter on a shortcut, then press the new keys. Delete: back to the default keys, "
                 + "or remove an application shortcut.",
                   "Enter na skrócie, potem naciśnij nowe klawisze. Delete: powrót do domyślnych klawiszy "
                 + "albo usunięcie skrótu aplikacji.")
    }

    Label {
        width: root.width
        visible: root.blad !== ""
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        color: Theme.ember
        bottomPadding: Theme.spacingSm
        text: root.blad
    }

    // ---------------- APPLICATIONS ----------------
    SectionLabel { rawText: Tr.t("Applications", "Aplikacje") }

    WierszOpcji {
        width: root.width
        visible: !root.dodawanie
        etykieta: Tr.t("New application shortcut", "Nowy skrót aplikacji")
        typ: "przycisk"
        tekst: Tr.t("add", "dodaj")
        onUzyto: root.zacznijDodawanie()
    }

    WierszOpcji {
        width: root.width
        visible: root.dodawanie
        etykieta: Tr.t("Search", "Szukaj")
        typ: "tekst"
        tekst: root.fraza
        onZmieniono: function (nowa) {
            root.fraza = nowa;
            root.indeksAplikacji = 0;
        }
    }

    WierszOpcji {
        width: root.width
        visible: root.dodawanie
        etykieta: Tr.t("Application", "Aplikacja")
        typ: "wybor"
        opcje: root.aplikacje.map(e => ({ kod: e.id, nazwa: e.name }))
        indeks: root.indeksAplikacji
        onZmieniono: function (nowa) { root.indeksAplikacji = nowa; }
    }

    WierszOpcji {
        width: root.width
        visible: root.dodawanie
        etykieta: Tr.t("Keys", "Klawisze")
        typ: "skrot"
        tekst: root.noweKlawisze !== "" ? UstawieniaHyprlanda.ladnie(root.noweKlawisze)
                                        : Tr.t("none - Enter", "brak - Enter")
        onEdycjaChanged: root.aktualizujPrzechwytywanie()
        onZmieniono: function (nowa) {
            if (root.sprawdz(nowa, "")) root.noweKlawisze = nowa;
        }
        onWyczyszczono: root.noweKlawisze = ""
    }

    WierszOpcji {
        width: root.width
        visible: root.dodawanie
        dostepny: root.aplikacja !== null && root.noweKlawisze !== ""
        etykieta: root.aplikacja ? root.aplikacja.name : Tr.t("No application found", "Nie znaleziono aplikacji")
        typ: "przycisk"
        tekst: Tr.t("save", "zapisz")
        onUzyto: {
            // Checked again - another shortcut may have taken the keys meanwhile.
            if (!root.sprawdz(root.noweKlawisze, "")) return;
            UstawieniaHyprlanda.dodajWlasny(root.noweKlawisze, root.aplikacja.name,
                                            UstawieniaHyprlanda.komendaAplikacji(root.aplikacja));
            root.zakonczDodawanie();
        }
    }

    WierszOpcji {
        width: root.width
        visible: root.dodawanie
        etykieta: Tr.t("Cancel", "Anuluj")
        typ: "przycisk"
        tekst: Tr.t("back", "wróć")
        onUzyto: {
            root.blad = "";
            root.zakonczDodawanie();
        }
    }

    Repeater {
        model: UstawieniaHyprlanda.wlasne

        delegate: WierszOpcji {
            required property var modelData

            width: root.width
            etykieta: modelData.nazwa
            typ: "skrot"
            tekst: UstawieniaHyprlanda.ladnie(modelData.klawisze)
            onEdycjaChanged: root.aktualizujPrzechwytywanie()
            onZmieniono: function (nowa) {
                if (root.sprawdz(nowa, modelData.klawisze))
                    UstawieniaHyprlanda.przeniesWlasny(modelData.klawisze, nowa);
            }
            onWyczyszczono: UstawieniaHyprlanda.usunWlasny(modelData.klawisze)
        }
    }

    // ---------------- EDITABLE ----------------
    SectionLabel { rawText: Tr.t("Shortcuts", "Skróty") }

    Repeater {
        model: UstawieniaHyprlanda.edytowalne

        delegate: WierszOpcji {
            required property var modelData

            readonly property bool zmieniony: !UstawieniaHyprlanda.tenSam(
                UstawieniaHyprlanda.rozbierz(modelData.klawisze),
                UstawieniaHyprlanda.rozbierz(modelData.domyslne))

            width: root.width
            etykieta: modelData.opis
            typ: "skrot"
            tekst: UstawieniaHyprlanda.ladnie(modelData.klawisze) + (zmieniony ? "  *" : "")
            onEdycjaChanged: root.aktualizujPrzechwytywanie()
            onZmieniono: function (nowa) {
                if (root.sprawdz(nowa, modelData.klawisze))
                    UstawieniaHyprlanda.zmienSkrot(modelData.id, nowa);
            }
            onWyczyszczono: {
                if (!zmieniony) return;
                if (root.sprawdz(modelData.domyslne, modelData.klawisze))
                    UstawieniaHyprlanda.przywrocSkrot(modelData.id);
            }
        }
    }

    // ---------------- FIXED ----------------
    SectionLabel { rawText: Tr.t("Fixed", "Stałe") }

    Repeater {
        model: UstawieniaHyprlanda.skroty

        delegate: WierszOpcji {
            required property var modelData

            width: root.width
            etykieta: modelData.opis
            typ: "info"
            tekst: modelData.klawisze
        }
    }
}
