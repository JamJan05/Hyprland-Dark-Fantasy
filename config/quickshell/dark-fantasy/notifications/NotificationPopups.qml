// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  POPUPS - notifications popping up in the corner.
//
//  Top right corner, below the bar - the same place SwayNC uses
//  (positionX right, positionY top in config/swaync/config.json).
//
//  ---------------------------------------------------------------
//  OVERLAY LAYER, NOT TOP
//
//  A popup must be visible also above a fullscreen window - otherwise
//  you miss a notification during a film or a presentation.
//  SwayNC had "layer": "overlay" for the same reason.
//
//  ---------------------------------------------------------------
//  THE INPUT MASK COVERS ONLY THE POPUPS
//
//  The window is a narrow column at the right edge, but when nothing is
//  showing, its mask has zero size and the mouse passes straight through.
//  Without that, a dead strip a few hundred pixels wide would eat clicks
//  in the windows underneath all the time.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import qs.services

PanelWindow {
    id: root

    WlrLayershell.namespace: "quickshell-popups"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.panelMarginTop
        right: Theme.panelMarginRight
    }

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: true

    readonly property int szerokosc: 400
    readonly property int zapasNaCien: Theme.shadowBlur + Theme.shadowOffsetY

    implicitWidth: szerokosc + 2 * zapasNaCien
    implicitHeight: Math.max(1, stos.implicitHeight + 2 * zapasNaCien)

    // Empty popup list = window transparent to the mouse.
    mask: Region {
        x: root.zapasNaCien
        y: root.zapasNaCien
        width: Notifications.popups.length > 0 ? root.szerokosc : 0
        height: Notifications.popups.length > 0 ? stos.implicitHeight : 0
    }

    Column {
        id: stos

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.zapasNaCien
        anchors.rightMargin: root.zapasNaCien

        width: root.szerokosc
        spacing: Theme.spacingSm

        Repeater {
            // ScriptModel, not the bare array: Notifications.popups is a new
            // array after every change, and a Repeater given a plain array
            // rebuilds ALL delegates. Each card then restarted its timer and
            // fade-in, so with notifications arriving less than 8 s apart
            // none ever disappeared. ScriptModel diffs the list and keeps the
            // delegates of notifications that are still there.
            model: ScriptModel { values: Notifications.popups }

            delegate: Item {
                id: miejsce
                required property var modelData

                width: stos.width
                height: karta.implicitHeight

                // The popup emerges with a crossfade and drifts 8 px
                // upward (Theme.driftDistance). No slide-in from the side - in
                // Dark Souls style nothing slides in, it just appears. Timings and curve are the same as for the panels
                // (leaf "layers" in hyprland.lua), so that everything on this
                // desktop has one tempo.
                Component.onCompleted: wjazd.start()

                DropShadow {
                    anchors.fill: karta
                    radius: karta.radius
                    opacity: karta.opacity
                }

                NotificationCard {
                    id: karta
                    width: parent.width
                    notification: miejsce.modelData
                    ephemeral: true

                    opacity: 0
                    y: Theme.driftDistance

                    ParallelAnimation {
                        id: wjazd
                        NumberAnimation {
                            target: karta; property: "opacity"
                            to: 1; duration: Theme.animPanelIn
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.easeOutQuint
                        }
                        NumberAnimation {
                            target: karta; property: "y"
                            to: 0; duration: Theme.animPanelIn
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Theme.easeOutQuint
                        }
                    }
                }
            }
        }
    }
}
