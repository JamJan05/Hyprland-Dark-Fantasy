// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  CARD - a surface for a group of controls inside a panel.
//
//  Counterpart of ".rzad" from panel-audio.css and the notification card
//  from swaync/style.css. The common denominator of both:
//      background = surface-alt at low alpha
//      corner     = two steps smaller than the panel holding it
//      border     = 1 px, gold at alpha .20
//
//  The card has no shadow - nothing in the shell does; an element
//  lying inside a panel is set apart by its background alone.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs

Rectangle {
    id: root

    // Whether the card reacts to the cursor. A section with sliders should not -
    // the slider has its own hover and two overlapping highlights
    // look like a glitch.
    property bool hoverEnabled: false

    // "Enabled" card - e.g. the selected power profile. It gets a
    // gold wash and a gold border, like the active desktop on the bar.
    property bool active: false

    property alias hovered: mouse.containsMouse

    implicitHeight: 0
    radius: Theme.radiusMedium

    color: active
        ? Theme.accentWash
        : (hoverEnabled && mouse.containsMouse
            ? Qt.alpha(Theme.surfaceAlt, 0.95)
            : Qt.alpha(Theme.surfaceAlt, 0.55))

    // The border is ALWAYS drawn, it only changes color. If it
    // appeared only on hover, the tile would jump
    // by 2 px the moment it is hovered. The same trick, for the same
    // reason, was used by the now-deleted nwg-drawer/drawer.css:
    //     "Przezroczysta ramka trzyma rozmiar kafelka stałym".
    border.width: Theme.borderWidth
    border.color: active ? Theme.borderActive : Theme.border

    Behavior on color {
        ColorAnimation {
            duration: Theme.animNormal
            easing.type: Easing.OutCubic
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Theme.animNormal
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: root.hoverEnabled
        // The card itself handles nothing - clicks are caught by the
        // controls inside. Without this the MouseArea would eat their events.
        acceptedButtons: Qt.NoButton
    }
}
