// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  SLOT - one program in the Arsenal grid.
//
//      ┌────────┐
//      │ ▒▒▒▒▒▒ │   48 x 48 px, 1 px frame, grain in the background,
//      │ ▒ icon▒│   32 px icon toned down by a filter, vignette in the corners
//      └────────┘
//
//  Inventory from the game: items sit in square slots. Here the frame IS
//  drawn in QML - unlike the tiles in the row, program icons do not
//  have their own frame, and without one the grid would fall apart into loose images.
//
//  ICON FILTER
//
//  Icons from the theme are colourful and "flat", as if from another world. So they
//  go through a MultiEffect (desaturation, a light old-gold tint, slightly
//  raised contrast) and under the vignette - the texture assets/winieta.png
//  from tools/generuj-winiete.py, which darkens the slot edges. The selected
//  slot gets its full colours back, a gold frame and a gold wash - "this is
//  the item you hold in your hand".
//
//  The effect only costs for slots visible on screen: the grid is a
//  GridView, which creates delegates only for the visible slice of the list.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import QtQuick.Effects
import Quickshell
import qs
import qs.components
import qs.services

Item {
    id: root

    // .desktop entry.
    property var entry: null

    property bool wybrany: false

    // The cursor moves over the slot - x, y in WINDOW coordinates. From these
    // the Arsenal tells real mouse movement apart from a slot that slid
    // under a stationary cursor while scrolling (see najechanoNa).
    signal najechano(real x, real y)
    signal kliknieto()

    implicitWidth: 48
    implicitHeight: 48

    readonly property string sciezkaIkony: AppIcons.path(entry)

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: root.wybrany ? Theme.accent : Theme.border

        Behavior on border.color { ColorAnimation { duration: Theme.animNormal } }

        Szum {
            anchors.fill: parent
            anchors.margins: Theme.borderWidth
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.borderWidth
        color: Theme.accentWash
        opacity: root.wybrany ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
    }

    Image {
        id: ikona
        anchors.centerIn: parent
        width: 32
        height: 32
        source: root.sciezkaIkony
        sourceSize.width: 64
        sourceSize.height: 64
        asynchronous: true
        smooth: true
        visible: false
    }

    MultiEffect {
        anchors.fill: ikona
        source: ikona
        visible: root.sciezkaIkony !== "" && ikona.status === Image.Ready
        // -0.85, not -0.65: at -0.65 Spotify green and Brave orange
        // still glowed against the stone (checked on a screenshot). On top of
        // that a light wash of Theme.accent (#b19a67), so the grey icons sit in
        // the palette instead of looking like cut-outs. The selected one gets
        // its full colours back - it is the only item "in hand".
        saturation: root.wybrany ? 0 : -0.85
        colorization: root.wybrany ? 0 : 0.25
        colorizationColor: Theme.accent
        contrast: 0.15

        Behavior on saturation { NumberAnimation { duration: Theme.animNormal } }
        Behavior on colorization { NumberAnimation { duration: Theme.animNormal } }
    }

    // Fallback glyph when the icon theme does not know the program.
    Label {
        anchors.centerIn: parent
        visible: root.sciezkaIkony === "" || ikona.status === Image.Error
        text: Icons.window
        font.pixelSize: 24
        color: root.wybrany ? Theme.textMuted : Theme.iron
    }

    // Vignette above the icon - inside the frame, so it does not dim the outline.
    Image {
        anchors.fill: parent
        anchors.margins: Theme.borderWidth
        source: "file://" + Quickshell.shellPath("assets/winieta.png")
        smooth: true
        cache: true
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onPositionChanged: function (zdarzenie) {
            const p = mapToItem(null, zdarzenie.x, zdarzenie.y);
            root.najechano(p.x, p.y);
        }
        onClicked: root.kliknieto()
    }
}
