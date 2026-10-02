// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  QUICK PANEL - Wi-Fi or Bluetooth, from under its own icon.
//
//  One window serves both, because they differ only in content:
//  the same surface, the same animation, the same input mask
//  and the same way of closing. Two separate files would be two
//  copies of the same skeleton.
//
//  The content is EXACTLY the same sections that live in System Control
//  Center - NetworkSection and BluetoothSection. There is no second
//  implementation and no second source of state: toggle Wi-Fi here,
//  and the big panel shows the same, because both read services/Network.qml.
//
//  ---------------------------------------------------------------
//  WHY THE POSITION FOLLOWS THE CURSOR
//
//  The panel should slide out from under the icon that was clicked. That
//  icon's position cannot be hard-coded, though: bar modules have
//  content-dependent widths (CPU percentage, temperature, signal
//  strength), so "network" and "bluetooth" drift horizontally on
//  every change of those values.
//
//  So on open we ask the compositor for the cursor position
//  (hyprctl cursorpos) and center the panel under it. One process per
//  open - it is a user action, not a loop.
//
//  When opened via a keyboard shortcut the cursor can be anywhere, so
//  the result is clamped to the screen and at worst the panel
//  appears at the edge. It will always be fully visible.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.components
import qs.services

PanelWindow {
    id: root

    // "wifi" | "bluetooth" | "" (closed). INPUT - set by
    // shell.qml. The panel never writes here itself, because that would break
    // the binding and from then on its state would diverge from the state
    // IPC knows. Instead it asks via a signal, and the shell decides.
    property string mode: ""

    readonly property bool open: mode !== ""

    signal closeRequested()
    signal openRequested(string co)

    // Open request. The mode does NOT change right away - first we ask
    // for the cursor position, so the panel has no time to flash in the old spot,
    // and only then do we ask the shell to change state.
    function request(co: string) {
        oczekujacyTryb = co;
        pytajOKursor.running = true;
    }

    property string oczekujacyTryb: ""

    WlrLayershell.namespace: "quickshell-quick"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.open
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: true

    mask: Region {
        x: 0
        y: Theme.panelMarginTop
        width: root.open ? root.width : 0
        height: root.open ? root.height - Theme.panelMarginTop : 0
    }

    readonly property int szerokosc: 360

    // Horizontal center of the panel. Set on open from the cursor
    // position; until the first open it sits at the right edge.
    property int srodek: root.width - szerokosc / 2 - Theme.panelMarginRight

    Process {
        id: pytajOKursor
        command: ["hyprctl", "cursorpos"]
        stdout: StdioCollector { id: pozycja }

        onExited: function (kod) {
            if (kod === 0) {
                // Format: "1824, 216"
                const czesci = pozycja.text.trim().split(",");
                const x = parseInt(czesci[0], 10);
                if (!isNaN(x)) root.srodek = x;
            }
            // Only now do we request opening - the panel slides in directly
            // at the right spot, without a jump.
            root.openRequested(root.oczekujacyTryb);
        }
    }

    Item {
        id: odbiornikPanelu
        anchors.fill: parent
        focus: root.open
        Keys.onEscapePressed: root.closeRequested()

        // Same as the tile row's receiver (kafle/RzadKafli.qml): after the
        // Wi-Fi password field goes away the focus comes back here, so Esc
        // closes the panel again.
        readonly property Item fokusOkna: Window.activeFocusItem
        onFokusOknaChanged: {
            if (!root.open || fokusOkna === odbiornikPanelu) return;
            if (fokusOkna !== null && fokusOkna.visible && fokusOkna.echoMode !== undefined) return;
            Qt.callLater(() => { if (root.open) odbiornikPanelu.forceActiveFocus(); });
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.open
        onClicked: root.closeRequested()
    }

    PanelSurface {
        id: powierzchnia

        anchors.top: parent.top
        anchors.topMargin: Theme.panelMarginTop

        width: root.szerokosc

        // Centered under the cursor, but never off screen.
        x: Math.max(Theme.panelMarginRight,
             Math.min(root.width - width - Theme.panelMarginRight,
                      root.srodek - width / 2))

        implicitHeight: Math.min(
            tresc.implicitHeight + 2 * padding,
            root.height - Theme.panelMarginTop - Theme.panelMarginRight)

        open: root.open
        attachedTop: true
        slideDistance: 0

        Flickable {
            anchors.fill: parent
            contentHeight: tresc.implicitHeight
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 6000
            clip: true

            Column {
                id: tresc
                width: parent.width
                spacing: Theme.spacingMd

                // The sections draw their own header ("NETWORK", "BLUETOOTH"),
                // so the panel adds no title of its own - it would be a second
                // caption saying the same thing.
                NetworkSection {
                    width: parent.width
                    visible: root.mode === "wifi"
                    panelOpen: root.mode === "wifi"
                }

                BluetoothSection {
                    width: parent.width
                    visible: root.mode === "bluetooth"
                    panelOpen: root.mode === "bluetooth"
                }
            }
        }
    }
}
