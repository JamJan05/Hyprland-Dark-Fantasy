// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  TILE CONTENT - the panel above the row in pause mode.
//
//  In the game, the content of the chosen menu tab opens above it. Four
//  tiles have their own content:
//
//      Arsenal     program grid with item description     kafle/Uzbrojenie.qml
//      Tidings     notification history                   kafle/Wiesci.qml
//      Cogwheel    settings                               kafle/Zebatka.qml
//      Bonfire     session menu                           kafle/Ognisko.qml
//
//  The tiles without it (Satchel, Status) get this panel when they are
//  selected in pause: a description and what Enter will do - open the
//  existing window or launch a program.
//
//  Frame, background and grain the same as in every shell panel.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs
import qs.components
import qs.services

Item {
    id: root

    // Tile description from the list in RzadKafli.qml: { klucz, nazwa, naglowek, opis, akcja }.
    property var kafel: null
    property bool widoczny: false

    implicitWidth: 520
    implicitHeight: tresc.implicitHeight + 2 * Theme.spacingLg

    opacity: widoczny ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: root.widoczny ? Theme.animPanelIn : Theme.animPanelOut
            easing.type: Easing.Bezier
            easing.bezierCurve: Theme.easeOutQuint
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.background, Theme.panelOpacity)
        border.width: Theme.borderWidth
        border.color: Theme.border

        // A click on the panel must not fall through to the dimming beneath it
        // and close the pause - see "CLICK EATER" in PanelSurface.qml.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Szum {
            anchors.fill: parent
            anchors.margins: Theme.borderWidth
        }
    }

    Column {
        id: tresc
        x: Theme.spacingLg
        y: Theme.spacingLg
        width: parent.width - 2 * Theme.spacingLg
        spacing: Theme.spacingSm

        Tytul {
            width: parent.width
            text: root.kafel ? root.kafel.naglowek : ""
        }

        Label {
            width: parent.width
            wrapMode: Text.Wrap
            elide: Text.ElideNone
            color: Theme.textMuted
            text: root.kafel ? root.kafel.opis : ""
        }

        Label {
            width: parent.width
            visible: root.kafel !== null && root.kafel.akcja !== ""
            topPadding: Theme.spacingXs
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.iron
            text: root.kafel
                ? "Enter  ·  " + root.kafel.akcja + "      Esc  ·  " + Tr.t("back", "wróć")
                : ""
        }
    }
}
