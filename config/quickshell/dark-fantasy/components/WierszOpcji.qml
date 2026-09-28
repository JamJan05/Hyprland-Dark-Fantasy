// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  OPTION ROW - "label ........ value", like options in the Dark Souls menu.
//
//      Gap between windows      ▐██████░░░░░░░░   5
//      Blur                                 On   Off
//      Keyboard layout                    ‹ polski ›
//
//  One component for all kinds of values - chosen via "typ":
//
//      suwak        6 px bar as in the HUD, number beside it (mono)
//      przelacznik  ON / OFF (PrzelacznikTekstowy)
//      wybor        ‹ name › from the "opcje" list
//      tekst        caption edited from the keyboard (floor names)
//      przycisk     caption in gold, Enter or click
//      skrot        keys of a shortcut: Enter or click waits for a new
//                   combination (reported by "zmieniono"), Esc cancels,
//                   Delete reports "wyczyszczono"
//      info         value only, no change
//
//  KEYBOARD. Focus is held by the tile row (kafle/RzadKafli.qml), and the Cogwheel
//  forwards keys to the selected row via klawisz() - just like
//  Arsenal. ← → change the value, Enter toggles / selects / starts
//  editing. The row sets nothing itself: it reports "zmieniono" with the new
//  value, and the caller does the saving (services/UstawieniaHyprlanda.qml).
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs
import qs.services

Item {
    id: root

    property string etykieta: ""
    property string typ: "info"

    // Selected with arrows or the mouse.
    property bool zaznaczony: false

    // ---- suwak ----
    property real wartosc: 0
    property real od: 0
    property real doo: 1
    property real krok: 0.1
    // Converts the value to the text beside the bar, e.g. v => v + " px".
    property var formatuj: v => String(v)

    // ---- przelacznik ----
    property bool wlaczony: false

    // ---- wybor ----
    property var opcje: []          // [{ kod, nazwa }]
    property int indeks: 0

    // ---- tekst / info / przycisk ----
    property string tekst: ""
    property bool edycja: false
    property string roboczy: ""     // text while editing

    property bool dostepny: true

    signal zmieniono(var nowa)
    signal uzyto()
    signal najechano()
    signal wyczyszczono()

    implicitHeight: 34
    opacity: dostepny ? 1 : Theme.disabledOpacity

    // ---------------------------------------------------------------
    //  KEYBOARD
    // ---------------------------------------------------------------
    function klawisz(zdarzenie: var): bool {
        if (!dostepny) return false;

        if (typ === "skrot" && edycja) {
            if (zdarzenie.key === Qt.Key_Escape) {
                edycja = false;
                return true;
            }
            // A modifier alone or a key that cannot be bound - keep waiting.
            const klawisze = UstawieniaHyprlanda.klawiszeZeZdarzenia(zdarzenie);
            if (klawisze === "") return true;
            edycja = false;
            zmieniono(klawisze);
            return true;    // while capturing nothing leaks to the row
        }

        if (typ === "tekst" && edycja) {
            switch (zdarzenie.key) {
            case Qt.Key_Return:
            case Qt.Key_Enter:
                edycja = false;
                zmieniono(roboczy);
                return true;
            case Qt.Key_Escape:
                edycja = false;
                return true;
            case Qt.Key_Backspace:
                roboczy = roboczy.slice(0, -1);
                return true;
            }
            const t = zdarzenie.text;
            if (t.length === 1 && t.charCodeAt(0) >= 32 && roboczy.length < 24) {
                roboczy += t;
                return true;
            }
            return true;    // while editing nothing leaks to the row
        }

        const lewo = zdarzenie.key === Qt.Key_Left;
        const prawo = zdarzenie.key === Qt.Key_Right;
        const enter = zdarzenie.key === Qt.Key_Return || zdarzenie.key === Qt.Key_Enter;

        switch (typ) {
        case "suwak":
            if (lewo || prawo) {
                zmieniono(przytnij(wartosc + (prawo ? krok : -krok)));
                return true;
            }
            break;
        case "przelacznik":
            if (lewo || prawo || enter) {
                zmieniono(lewo ? true : prawo ? false : !wlaczony);
                return true;
            }
            break;
        case "wybor":
            if ((lewo || prawo || enter) && opcje.length > 0) {
                const n = opcje.length;
                zmieniono(((indeks + (lewo ? -1 : 1)) % n + n) % n);
                return true;
            }
            break;
        case "tekst":
            if (enter) {
                roboczy = tekst;
                edycja = true;
                return true;
            }
            break;
        case "przycisk":
            if (enter) {
                uzyto();
                return true;
            }
            break;
        case "skrot":
            if (enter) {
                edycja = true;
                return true;
            }
            if (zdarzenie.key === Qt.Key_Delete || zdarzenie.key === Qt.Key_Backspace) {
                wyczyszczono();
                return true;
            }
            break;
        }
        return false;
    }

    // Capture that got no key in 10 s gives up - the section switches
    // Hyprland back to its normal shortcuts when "edycja" drops.
    Timer {
        interval: 10000
        running: root.typ === "skrot" && root.edycja
        onTriggered: root.edycja = false
    }

    function przytnij(v: real): real {
        const k = Math.round((v - od) / krok);
        return Math.max(od, Math.min(doo, od + k * krok));
    }

    // ---------------------------------------------------------------
    //  APPEARANCE
    // ---------------------------------------------------------------

    // Selection - a gold wash and a marker at the left edge, like
    // entries in the Bonfire.
    Rectangle {
        anchors.fill: parent
        color: Theme.accentWash
        opacity: root.zaznaczony ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
    }

    Rectangle {
        width: 2
        height: parent.height
        color: Theme.accent
        opacity: root.zaznaczony ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
    }

    Text {
        id: napis
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingMd
        anchors.right: wartoscPole.left
        anchors.rightMargin: Theme.spacingMd
        anchors.verticalCenter: parent.verticalCenter
        text: root.etykieta
        elide: Text.ElideRight
        font.family: Theme.fontDisplay
        font.pixelSize: Theme.fontSizeNormal + 3
        font.capitalization: Font.SmallCaps
        font.features: { "lnum": 1 }
        font.letterSpacing: 1.25
        color: root.zaznaczony ? Theme.text : Theme.textMuted
        Behavior on color { ColorAnimation { duration: Theme.animNormal } }
    }

    Item {
        id: wartoscPole
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingMd
        anchors.verticalCenter: parent.verticalCenter
        width: 250
        height: parent.height

        // ---- suwak: bar as in the HUD ----
        Item {
            anchors.fill: parent
            visible: root.typ === "suwak"

            StatBar {
                id: pasek
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                length: 180
                fillColor: Theme.accent
                value: root.doo > root.od ? (root.wartosc - root.od) / (root.doo - root.od) : 0
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 58
                horizontalAlignment: Text.AlignRight
                text: root.formatuj(root.wartosc)
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeSmall + 1
                color: root.zaznaczony ? Theme.text : Theme.textMuted
            }

            MouseArea {
                x: pasek.x
                width: pasek.width
                height: parent.height
                cursorShape: Qt.PointingHandCursor
                enabled: root.dostepny

                function ustawZ(mx: real): void {
                    const u = Math.max(0, Math.min(1, mx / width));
                    root.zmieniono(root.przytnij(root.od + u * (root.doo - root.od)));
                }

                onPressed: function (z) { ustawZ(z.x); }
                onPositionChanged: function (z) { if (pressed) ustawZ(z.x); }
            }
        }

        // ---- przelacznik (toggle) ----
        PrzelacznikTekstowy {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.typ === "przelacznik"
            checked: root.wlaczony
            enabled: root.dostepny
            onToggled: root.zmieniono(!root.wlaczony)
        }

        // ---- wybor (choice) ----
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.typ === "wybor"
            spacing: Theme.spacingSm

            component Strzalka: Text {
                property int kierunek: 1
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeLarge + 2
                color: root.zaznaczony ? Theme.accent : Theme.iron

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.dostepny && root.opcje.length > 0
                    onClicked: {
                        const n = root.opcje.length;
                        root.zmieniono(((root.indeks + parent.kierunek) % n + n) % n);
                    }
                }
            }

            Strzalka { text: "‹"; kierunek: -1 }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 170
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.opcje.length > 0 && root.indeks >= 0 && root.indeks < root.opcje.length
                    ? root.opcje[root.indeks].nazwa : "-"
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeNormal + 3
                font.features: { "lnum": 1 }
                color: root.zaznaczony ? Theme.text : Theme.textMuted
            }

            Strzalka { text: "›"; kierunek: 1 }
        }

        // ---- tekst, info, przycisk (text, info, button) ----
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
            visible: root.typ === "tekst" || root.typ === "info" || root.typ === "przycisk" || root.typ === "skrot"
            text: root.typ === "tekst"
                ? (root.edycja ? root.roboczy + "_" : (root.tekst !== "" ? root.tekst : Tr.t("untitled", "bez nazwy")))
                : root.typ === "skrot" && root.edycja
                ? Tr.t("press the keys…  Esc - cancel", "naciśnij klawisze…  Esc - anuluj")
                : root.tekst
            font.family: root.typ === "info" ? Theme.fontMono : Theme.fontDisplay
            font.pixelSize: root.typ === "info" ? Theme.fontSizeSmall + 1 : Theme.fontSizeNormal + 3
            font.capitalization: root.typ === "przycisk" ? Font.SmallCaps : Font.MixedCase
            font.italic: root.typ === "tekst" && root.tekst === "" && !root.edycja
            color: root.typ === "przycisk" || (root.typ === "skrot" && root.edycja) ? Theme.accent
                 : root.edycja ? Theme.text
                 : root.zaznaczony ? Theme.text : Theme.textMuted
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onContainsMouseChanged: {
            if (!containsMouse) return;
            root.najechano();
            // The option section (system/SekcjaOpcji.qml) moves the selection
            // to the row under the cursor.
            if (root.parent && root.parent.wybierzWiersz !== undefined) root.parent.wybierzWiersz(root);
        }
        onClicked: {
            if (root.typ === "przycisk") root.uzyto();
            else if (root.typ === "tekst") { root.roboczy = root.tekst; root.edycja = true; }
            else if (root.typ === "skrot") root.edycja = true;
            else if (root.typ === "przelacznik") root.zmieniono(!root.wlaczony);
        }
    }
}
