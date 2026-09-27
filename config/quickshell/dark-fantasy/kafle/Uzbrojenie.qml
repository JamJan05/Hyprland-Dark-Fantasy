pragma ComponentBehavior: Bound

// Pragma on the first line, before the comment - reason in Icons.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  ARSENAL - every program, in the layout of an in-game inventory.
//
//      ┌───────────────────────────────────┬───────────────────────┐
//      │ ▢ ▢ ▢ ▢ ▢ ▢ ▢ ▢ ▢                │ KITTY                  │
//      │ ▢ ▢ ▣ ▢ ▢ ▢ ▢ ▢ ▢                │ terminal emulator      │
//      │ ▢ ▢ ▢ ▢ ▢ ▢ ▢ ▢ ▢                │ ─────────────────────  │
//      │ ...                               │ Fast, GPU-based        │
//      │ ─ kit_ ─────────────────────────  │ terminal emulator.     │
//      │                                   │              kitty     │
//      └───────────────────────────────────┴───────────────────────┘
//
//  Content of the Arsenal tile, opened above the tile row. Replaced the app
//  menu, which was a separate window in the middle of the screen.
//
//  LEFT COLUMN - grid of 48 px slots (kafle/SlotAplikacji.qml).
//  RIGHT COLUMN - "item description": the name in small caps, below it the generic
//  name, and further down Comment= from the .desktop file in italics - the way a weapon
//  description reads in the game. At the very bottom, in small print, the Exec command. The description follows
//  the selection - with arrow keys or mouse hover, no clicking.
//
//  SEARCH WITHOUT A FIELD. Just start typing: at the bottom of the grid
//  a thin gold line with the typed text appears, and the grid filters.
//  Backspace deletes, Esc first clears the search, and only the next
//  Esc returns to the tile row. Enter launches the selected program.
//
//  No favourites row and no pinning - the favourites from the old menu
//  disappeared together with the dock, which was their other half.
//
//  THE KEYBOARD IS NOT OWNED HERE. Focus is held by the tile row (one focus
//  owner - the pitfall with opening the old menu) and it passes keys to
//  klawisz() below when it is on the content level. Thanks to that there is
//  no text field here that could steal or lose focus.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import Quickshell
import qs
import qs.components
import qs.services
import "nawigacja.js" as Nawigacja

Item {
    id: root

    property bool widoczny: false

    // Content level - keys go to the grid.
    property bool aktywny: false

    signal uruchomiono()

    // ---------------------------------------------------------------
    //  DIMENSIONS
    // ---------------------------------------------------------------
    readonly property int kolumny: 9
    readonly property int wierszeWidoczne: 6
    readonly property int komorka: 54              // slot 48 + spacing 6
    readonly property int margines: Theme.spacingLg
    readonly property int szerokoscOpisu: 300
    readonly property int wysokoscWyszukiwania: 30

    implicitWidth: margines + kolumny * komorka + margines + szerokoscOpisu + margines
    implicitHeight: margines + wierszeWidoczne * komorka + wysokoscWyszukiwania + margines

    opacity: widoczny ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: root.widoczny ? Theme.animPanelIn : Theme.animPanelOut
            easing.type: Easing.Bezier
            easing.bezierCurve: Theme.easeOutQuint
        }
    }

    // Every opening starts with a clean grid - like the old menu.
    onWidocznyChanged: {
        if (widoczny) {
            fraza = "";
            wybrany = 0;
            kursorZnany = false;
            siatka.positionViewAtBeginning();
        }
    }

    // ---------------------------------------------------------------
    //  PROGRAM LIST
    // ---------------------------------------------------------------

    // "noDisplay" marks entries that themselves ask not to be shown -
    // protocol handlers, helper invocations of packages. Referencing
    // applications.values recomputes the list once the entry scan finishes
    // (pitfall 7 in the Quickshell notes).
    readonly property var wszystkie: {
        const l = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        l.sort((a, b) => a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1);
        return l;
    }

    property string fraza: ""
    readonly property string szukane: fraza.trim().toLowerCase()

    function pasuje(e: var, q: string): bool {
        if (e.name.toLowerCase().indexOf(q) !== -1) return true;
        if (e.genericName && e.genericName.toLowerCase().indexOf(q) !== -1) return true;
        if (e.comment && e.comment.toLowerCase().indexOf(q) !== -1) return true;
        if (e.keywords && e.keywords.some(k => k.toLowerCase().indexOf(q) !== -1)) return true;
        return e.id.toLowerCase().indexOf(q) !== -1;
    }

    readonly property var widoczne: szukane === ""
        ? wszystkie
        : wszystkie.filter(e => root.pasuje(e, szukane))

    property int wybrany: 0

    readonly property var zaznaczony:
        wybrany >= 0 && wybrany < widoczne.length ? widoczne[wybrany] : null

    onSzukaneChanged: {
        wybrany = 0;
        siatka.positionViewAtBeginning();
    }

    function uruchom(e: var): void {
        if (!e) return;
        e.execute();
        root.uruchomiono();
    }

    function przesun(dx: int, dy: int): void {
        const nowy = Nawigacja.ruch(wybrany, dx, dy, [widoczne.length], kolumny);
        if (nowy < 0) return;
        wybrany = nowy;
        siatka.positionViewAtIndex(wybrany, GridView.Contain);
    }

    // MOUSE AND SELECTION - the same guard as in the old menu: the selection
    // follows the mouse only on REAL cursor movement. Slots slide by
    // themselves under a stationary cursor on opening and with every typed letter,
    // and then Enter would launch a different program from the one you searched for.
    property point kursor: Qt.point(-1, -1)
    property bool kursorZnany: false

    function najechanoNa(i: int, x: real, y: real): void {
        const pierwsze = !kursorZnany;
        const stoi = kursorZnany && x === kursor.x && y === kursor.y;
        kursor = Qt.point(x, y);
        kursorZnany = true;
        if (pierwsze || stoi) return;
        wybrany = i;
    }

    // ---------------------------------------------------------------
    //  KEYBOARD - called by kafle/RzadKafli.qml. Returns true when the
    //  key was handled; false hands it back to the row (Esc = level up).
    // ---------------------------------------------------------------
    function klawisz(zdarzenie: var): bool {
        switch (zdarzenie.key) {
        case Qt.Key_Left:   przesun(-1, 0); return true;
        case Qt.Key_Right:  przesun(1, 0);  return true;
        case Qt.Key_Up:     przesun(0, -1); return true;
        case Qt.Key_Down:   przesun(0, 1);  return true;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            uruchom(zaznaczony);
            return true;
        case Qt.Key_Backspace:
            fraza = fraza.slice(0, -1);
            return true;
        case Qt.Key_Escape:
            if (fraza === "") return false;
            fraza = "";
            return true;
        }

        if (jestTekstem(zdarzenie)) {
            fraza += zdarzenie.text;
            return true;
        }
        return false;
    }

    // Letter, digit, space - into the search. Shortcuts with Ctrl, Alt
    // and the Windows key are not typing. Also asked by the tile row, which
    // opens the pause from rest only for typing.
    function jestTekstem(zdarzenie: var): bool {
        const mody = Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier;
        // One code point, not one UTF-16 unit - an emoji is two units.
        const t = zdarzenie.text;
        const kod = t.codePointAt(0);
        return [...t].length === 1 && kod >= 32 && kod !== 127
            && (zdarzenie.modifiers & mody) === 0;
    }

    // ---------------------------------------------------------------
    //  FRAME
    // ---------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.background, Theme.panelOpacity)
        border.width: Theme.borderWidth
        border.color: Theme.border

        // A click on an empty spot of the panel must not fall through to
        // the pause dimming and close it.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Szum {
            anchors.fill: parent
            anchors.margins: Theme.borderWidth
        }
    }

    // ---------------------------------------------------------------
    //  GRID
    // ---------------------------------------------------------------
    GridView {
        id: siatka

        x: root.margines
        y: root.margines
        width: root.kolumny * root.komorka
        height: root.wierszeWidoczne * root.komorka

        cellWidth: root.komorka
        cellHeight: root.komorka
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        model: root.widoczne

        delegate: SlotAplikacji {
            required property var modelData
            required property int index

            entry: modelData
            wybrany: root.wybrany === index

            onNajechano: function (x, y) { root.najechanoNa(index, x, y); }
            onKliknieto: root.uruchom(modelData)
        }
    }

    Label {
        anchors.centerIn: siatka
        visible: root.widoczne.length === 0
        font.family: Theme.fontDisplay
        font.pixelSize: Theme.fontSizeLarge
        font.italic: true
        color: Theme.iron
        text: Tr.t("Nothing matches “" + root.fraza + "”.",
                   "Nic nie pasuje do „" + root.fraza + "”.")
    }

    // ---------------------------------------------------------------
    //  SEARCH LINE - appears only once something has been typed.
    // ---------------------------------------------------------------
    Item {
        x: siatka.x
        y: siatka.y + siatka.height + 4
        width: siatka.width - 6
        height: root.wysokoscWyszukiwania - 4

        opacity: root.fraza !== "" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }

        Label {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -2
            width: parent.width
            text: root.fraza + "_"
            color: Theme.text
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Theme.accent
            opacity: 0.6
        }
    }

    // ---------------------------------------------------------------
    //  ITEM DESCRIPTION
    // ---------------------------------------------------------------
    Item {
        x: siatka.x + siatka.width + root.margines - 6
        y: root.margines
        width: root.szerokoscOpisu
        height: root.height - 2 * root.margines

        Column {
            width: parent.width
            spacing: Theme.spacingSm

            Tytul {
                width: parent.width
                text: root.zaznaczony ? root.zaznaczony.name : ""
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.zaznaczony ? root.zaznaczony.genericName : ""
                elide: Text.ElideRight
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeNormal + 2
                font.capitalization: Font.SmallCaps
                font.features: { "lnum": 1 }
                font.letterSpacing: 1
                color: Theme.textMuted
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }

            // Item description - italic of the title typeface, like a weapon description
            // in the game. The EB Garamond package has a true italic (Italic),
            // so this is not a slanted regular face.
            Text {
                width: parent.width
                topPadding: Theme.spacingXs
                wrapMode: Text.Wrap
                maximumLineCount: 8
                elide: Text.ElideRight
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeLarge + 1
                font.italic: true
                lineHeight: 1.1
                color: root.zaznaczony && root.zaznaczony.comment !== "" ? Theme.text : Theme.iron
                text: root.zaznaczony
                    ? (root.zaznaczony.comment !== "" ? root.zaznaczony.comment
                                                        : Tr.t("No description.", "Brak opisu."))
                    : ""
            }
        }

        // The command - small print, at the very bottom.
        Label {
            anchors.bottom: parent.bottom
            width: parent.width
            elide: Text.ElideMiddle
            font.pixelSize: Theme.fontSizeSmall - 1
            color: Theme.iron
            text: root.zaznaczony ? root.zaznaczony.execString : ""
        }
    }
}
