// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  COGWHEEL - settings above the tile row.
//
//  Just the frame: background, noise, crossfade - same as Bonfire and Tidings. The content
//  (two columns of sections and options) is system/CentrumUstawien.qml, because
//  the sections it is built from live there too.
//
//  It is opened by the tile, SUPER+U (GlobalShortcut "systemToggle" in shell.qml)
//  and "qs -c dark-fantasy ipc call system toggle". There is a single way into
//  settings - no cogwheel on Waybar.
//
//  Fixed size: the frame must not jump when the section changes, because every
//  jump moves the line above the row and looks like a glitch.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs
import qs.components
import qs.system

Item {
    id: root

    property bool widoczny: false
    property bool aktywny: false

    signal dotknieto()

    implicitWidth: 920
    implicitHeight: 560

    opacity: widoczny ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: root.widoczny ? Theme.animPanelIn : Theme.animPanelOut
            easing.type: Easing.Bezier
            easing.bezierCurve: Theme.easeOutQuint
        }
    }

    function klawisz(zdarzenie: var): bool {
        return centrum.klawisz(zdarzenie);
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.background, Theme.panelOpacity)
        border.width: Theme.borderWidth
        border.color: Theme.border

        // A click on the frame background must not fall through to the pause
        // dimming - that would close it.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Szum {
            anchors.fill: parent
            anchors.margins: Theme.borderWidth
        }
    }

    CentrumUstawien {
        id: centrum
        anchors.fill: parent
        anchors.margins: Theme.spacingLg
        widoczny: root.widoczny
        aktywny: root.aktywny
        onDotknieto: root.dotknieto()
    }
}
