// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  BLUETOOTH SECTION - power toggle, device list, connecting.
//
//  The backend is BlueZ, via Quickshell.Bluetooth. No stack of our own
//  and no calls to bluetoothctl - the Bluetooth singleton exposes
//  the adapter and devices over D-Bus, reactively.
//
//  ---------------------------------------------------------------
//  WHAT WE SHOW AND WHAT WE DON'T
//
//  BlueZ keeps in memory EVERY device that has ever been
//  in range - including strangers' headphones from the bus. So the list
//  shows only paired devices by default, and the rest only once
//  you turn on searching yourself. Without that, after a week the panel
//  would look like a directory of the neighbours' phones.
//
//  ---------------------------------------------------------------
//  SEARCHING TURNS ITSELF OFF
//
//  Scanning costs power and degrades audio connection quality, so
//  it turns off after a minute and when the panel closes. Bluetoothctl
//  left scanning is the classic reason for "why is this battery
//  draining so fast".
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import Quickshell.Bluetooth
import qs
import qs.components
import qs.services

Column {
    id: root

    // The panel sets this to false on close, to stop scanning.
    property bool panelOpen: false

    spacing: Theme.spacingMd

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool maAdapter: adapter !== null

    readonly property bool wlaczony:
        maAdapter && adapter.state === BluetoothAdapterState.Enabled

    // The adapter can take several seconds to power on - meanwhile
    // the toggle does not accept clicks.
    readonly property bool wPolowieDrogi:
        maAdapter && (adapter.state === BluetoothAdapterState.Enabling
                   || adapter.state === BluetoothAdapterState.Disabling)

    readonly property bool zablokowany:
        maAdapter && adapter.state === BluetoothAdapterState.Blocked

    // All devices known to the adapter.
    readonly property var wszystkie:
        maAdapter ? adapter.devices.values : []

    readonly property int polaczonych: {
        let n = 0;
        for (const u of wszystkie) if (u.connected) n++;
        return n;
    }

    // Paired ones plus - while scanning - everything visible on the air.
    // Connected always on top, then paired, then the rest.
    readonly property var widoczne: {
        const lista = [];
        for (const u of wszystkie) {
            if (u.connected || u.paired || u.bonded) lista.push(u);
            else if (maAdapter && adapter.discovering) lista.push(u);
        }
        lista.sort(function (a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            const ap = a.paired || a.bonded;
            const bp = b.paired || b.bonded;
            if (ap !== bp) return ap ? -1 : 1;
            return a.deviceName.localeCompare(b.deviceName);
        });
        return lista;
    }

    // Scanning stops together with the panel. This is not cosmetic -
    // active searching really drains the battery and worsens audio.
    onPanelOpenChanged: {
        if (!panelOpen && maAdapter && adapter.discovering) {
            adapter.discovering = false;
        }
    }

    Timer {
        id: koniecSkanowania
        interval: 60000
        onTriggered: if (root.maAdapter) root.adapter.discovering = false;
    }

    // ---------------------------------------------------------------
    //  HEADER WITH POWER TOGGLE
    // ---------------------------------------------------------------
    SectionLabel { rawText: "Bluetooth" }

    Card {
        width: parent.width
        implicitHeight: glowny.implicitHeight + 2 * Theme.spacingMd

        Item {
            id: glowny
            anchors.fill: parent
            anchors.margins: Theme.spacingMd
            implicitHeight: Math.max(ikona.implicitHeight, opisy.implicitHeight,
                                     przelacznik.implicitHeight)

            Label {
                id: ikona
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                font.pixelSize: Theme.fontSizeIcon
                text: !root.wlaczony       ? Icons.bluetoothOff
                    : root.polaczonych > 0 ? Icons.bluetoothConnected
                                           : Icons.bluetoothOn
                // A disabled controller should not catch the eye -
                // the same rule as "#bluetooth.off" in waybar/style.css.
                color: !root.wlaczony ? Theme.iron : Theme.accent

                Behavior on color { ColorAnimation { duration: Theme.animNormal } }
            }

            Column {
                id: opisy
                anchors.left: ikona.right
                anchors.leftMargin: Theme.spacingSm
                anchors.right: przelacznik.left
                anchors.rightMargin: Theme.spacingSm
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Label {
                    width: parent.width
                    text: "Bluetooth"
                    font.weight: Theme.fontWeightMedium
                }

                Label {
                    width: parent.width
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.zablokowany ? Theme.ember : Theme.textMuted
                    text: {
                        if (!root.maAdapter)   return Tr.t("No controller", "Brak kontrolera");
                        if (root.zablokowany)  return Tr.t("Blocked by rfkill", "Zablokowany przez rfkill");
                        if (root.wPolowieDrogi)
                            return root.adapter.state === BluetoothAdapterState.Enabling
                                ? Tr.t("Turning on…", "Włączanie…")
                                : Tr.t("Turning off…", "Wyłączanie…");
                        if (!root.wlaczony)    return Tr.t("Off", "Wyłączony");
                        if (root.polaczonych === 0)
                            return Tr.t("On, nothing connected", "Włączony, nic nie podłączone");
                        const n = root.polaczonych;
                        return n + " "
                            + Tr.forma(n, "device", "devices", "urządzenie", "urządzenia", "urządzeń")
                            + " "
                            + Tr.forma(n, "connected", "connected", "podłączone", "podłączone", "podłączonych");
                    }
                }
            }

            Toggle {
                id: przelacznik
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: root.wlaczony
                busy: root.wPolowieDrogi
                enabled: root.maAdapter && !root.zablokowany
                // Through PamiecBluetooth, so the change is saved at once.
                onToggled: PamiecBluetooth.ustaw(!root.adapter.enabled)
            }
        }
    }

    // ---------------------------------------------------------------
    //  DEVICE LIST
    // ---------------------------------------------------------------
    Column {
        width: parent.width
        spacing: Theme.spacingSm
        visible: root.wlaczony

        Repeater {
            model: root.widoczne

            delegate: BluetoothDeviceRow {
                required property var modelData
                width: parent.width
                device: modelData
            }
        }

        // Empty - but only when there is really nothing to show.
        Label {
            width: parent.width
            visible: root.widoczne.length === 0
            horizontalAlignment: Text.AlignHCenter
            padding: Theme.spacingMd
            font.pixelSize: Theme.fontSizeSmall
            font.italic: true
            color: Theme.iron
            text: root.adapter && root.adapter.discovering
                ? Tr.t("Searching for devices…", "Szukam urządzeń…")
                : Tr.t("No paired devices", "Brak sparowanych urządzeń")
        }

        // ---------- SEARCH ----------
        Item {
            width: parent.width
            height: 30

            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusSmall
                color: root.adapter && root.adapter.discovering
                    ? Theme.accentWash
                    : (szukajMysz.containsMouse
                        ? Qt.alpha(Theme.surfaceAlt, 0.95)
                        : Qt.alpha(Theme.surfaceAlt, 0.45))
                border.width: Theme.borderWidth
                border.color: root.adapter && root.adapter.discovering
                    ? Theme.borderActive : Theme.border

                Behavior on color { ColorAnimation { duration: Theme.animNormal } }
                Behavior on border.color { ColorAnimation { duration: Theme.animNormal } }
            }

            Label {
                anchors.centerIn: parent
                font.pixelSize: Theme.fontSizeSmall
                color: root.adapter && root.adapter.discovering
                    ? Theme.accent : Theme.textMuted
                text: root.adapter && root.adapter.discovering
                    ? Tr.t("Stop searching", "Przerwij wyszukiwanie")
                    : Tr.t("Search for devices", "Szukaj urządzeń")
            }

            MouseArea {
                id: szukajMysz
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.maAdapter) return;
                    const teraz = !root.adapter.discovering;
                    root.adapter.discovering = teraz;
                    if (teraz) koniecSkanowania.restart();
                    else koniecSkanowania.stop();
                }
            }
        }
    }
}
