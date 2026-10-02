// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  DESKTOPS OF THE CURRENT FLOOR - a row of small squares under the bars.
//
//      ■ □ □ □
//
//  In the game this is where the status icons sit under the bars. Here it holds the desktops
//  of the floor you are on: one 10 x 10 px square for each
//  existing desktop, in the order 1..9, 0.
//
//      active           filled with gold
//      others           empty 1 px frame
//      window awaits    ember-coloured frame ("urgent" event)
//        attention
//
//  A click switches the desktop, the wheel cycles through the floor's desktops - the same
//  as the digits on Waybar did. All the logic is in floors.lua; the state comes
//  from services/Pietra.qml.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.components
import qs.services

Row {
    id: root

    property Dymek dymek: null
    // Wheel delta summed across events, see onWheel below.
    property real sumaKolka: 0

    spacing: 4

    Repeater {
        model: Pietra.pulpity

        delegate: Rectangle {
            id: kwadrat

            required property var modelData

            width: 10
            height: 10

            color: modelData.aktywny ? Theme.accent : "transparent"
            border.width: Theme.borderWidth
            border.color: modelData.pilny ? Theme.ember
                : modelData.aktywny ? Theme.accent
                : Theme.border

            Behavior on color { ColorAnimation { duration: Theme.animNormal } }
            Behavior on border.color { ColorAnimation { duration: Theme.animNormal } }

            // Desktop digit - optional, see Theme.workspaceNumbers.
            Text {
                anchors.centerIn: parent
                visible: Theme.workspaceNumbers
                text: kwadrat.modelData.n % 10
                font.family: Theme.fontMono
                font.pixelSize: 8
                color: kwadrat.modelData.aktywny ? Theme.background : Theme.textMuted
            }

            MouseArea {
                // Hit area larger than the square - 10 px is hard to
                // aim at. It reaches half the spacing on each side.
                anchors.fill: parent
                anchors.margins: -2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: Pietra.naPulpit(kwadrat.modelData.n)
                // Summed like the emblem's wheel (hud/Godlo.qml): one step
                // per notch, a touchpad swipe is not a dozen steps, and a
                // horizontal event is not a step down.
                onWheel: function (zdarzenie) {
                    root.sumaKolka += zdarzenie.angleDelta.y;
                    while (Math.abs(root.sumaKolka) >= 120) {
                        const krok = root.sumaKolka > 0 ? 1 : -1;
                        root.sumaKolka -= krok * 120;
                        Pietra.krokPulpitu(krok);
                    }
                }
                onContainsMouseChanged: {
                    if (!root.dymek) return;
                    if (containsMouse)
                        root.dymek.pokaz(kwadrat, Tr.t("Desktop ", "Pulpit ") + (kwadrat.modelData.n % 10)
                            + (kwadrat.modelData.pilny
                               ? "\n" + Tr.t("a window needs attention", "okno czeka na uwagę")
                               : ""));
                    else
                        root.dymek.schowaj(kwadrat);
                }
            }
        }
    }
}
