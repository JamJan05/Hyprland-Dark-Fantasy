// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  EMBLEM - the current floor as a Roman numeral.
//
//      ┌──────┐
//      │┌────┐│
//      ││ II ││    30 x 30 px, double frame, grain in the background
//      │└────┘│
//      └──────┘
//
//  In the game this spot holds the covenant emblem. Here it holds the floor, because it is
//  what says "where I am" - just as the emblem says "whom I serve". No letters
//  "F" or "P": a Roman numeral reads as a storey number on its own.
//
//  Changing the floor crossfades the old numeral into the new one (300 ms). Two
//  text layers instead of one - a single numeral with an opacity animation
//  would first have to fade out and only then light up as the new one,
//  and for a moment the emblem would be empty.
//
//  The mouse wheel over the emblem changes the floor (up = higher).
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs
import qs.components
import qs.services

Item {
    id: root

    // Shared HUD tooltip - set by hud/Hud.qml.
    property Dymek dymek: null

    implicitWidth: 30
    implicitHeight: 30

    readonly property string cyfra: Pietra.rzymska(Pietra.pietro)

    // Crossfade layers - see the header.
    property string tekstA: ""
    property string tekstB: ""
    property bool naA: true

    Component.onCompleted: tekstA = cyfra

    onCyfraChanged: {
        if (naA) {
            tekstB = cyfra;
            naA = false;
        } else {
            tekstA = cyfra;
            naA = true;
        }
    }

    // Outer frame.
    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        border.width: Theme.borderWidth
        border.color: Theme.border

        Szum {
            anchors.fill: parent
            anchors.margins: Theme.borderWidth
        }

        // Inner frame, 2 px inward.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            color: "transparent"
            border.width: Theme.borderWidth
            border.color: Theme.border
        }
    }

    component Cyfra: Text {
        anchors.centerIn: parent
        width: 22
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: Theme.fontDisplay
        font.pixelSize: 17
        // "VIII" does not fit in 22 px at a 17 px typeface - it shrinks
        // by itself instead of spilling outside the frame.
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: 9
        color: Theme.accent

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }
    }

    Cyfra {
        text: root.tekstA
        opacity: root.naA ? 1 : 0
    }

    Cyfra {
        text: root.tekstB
        opacity: root.naA ? 0 : 1
    }

    HoverHandler {
        onHoveredChanged: {
            if (!root.dymek) return;
            if (hovered) root.dymek.pokaz(root, Tr.t("Floor ", "Piętro ") + Pietra.pietro + "\n"
                + Tr.t("scroll: change floor", "kółko: zmiana piętra"));
            else root.dymek.schowaj(root);
        }
    }

    // One step per wheel notch (120 units of angleDelta). A touchpad sends
    // many small events per swipe, so they are summed up - one event per
    // step jumped several floors at once. A purely horizontal event
    // (y === 0) adds nothing; it used to count as a step down.
    property real sumaKolka: 0

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function (zdarzenie) {
            root.sumaKolka += zdarzenie.angleDelta.y;
            while (Math.abs(root.sumaKolka) >= 120) {
                const krok = root.sumaKolka > 0 ? 1 : -1;
                root.sumaKolka -= krok * 120;
                Pietra.krokPietra(krok);
            }
        }
    }
}
