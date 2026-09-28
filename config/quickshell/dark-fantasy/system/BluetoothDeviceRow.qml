// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  A SINGLE BLUETOOTH DEVICE IN THE LIST.
//
//  A click connects or disconnects - depending on state. An unpaired
//  device gets paired first, because BlueZ will not allow
//  connecting without that anyway, and a separate "pair" button next to
//  "connect" would be a meaningless distinction for the user.
//
//  TRUSTED BEFORE PAIRING AND CONNECTING. After pairing, headphones open the
//  audio profiles (A2DP, HFP) THEMSELVES. BlueZ lets an untrusted device do
//  that only after asking an agent - and this session runs none (the shell
//  does not register one, and bluetoothctl's lives only while it runs). So
//  the request was refused and the headphones dropped a few seconds after
//  "Connected". A device chosen here by hand is marked trusted
//  (Device1.Trusted) first, which also lets it reconnect by itself later.
//
//  Battery level is shown only when the device reports it
//  (batteryAvailable). Headphones usually do, mice less often.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import Quickshell.Bluetooth
import qs
import qs.components
import qs.services

Card {
    id: root

    // BluetoothDevice object from Quickshell.Bluetooth.
    property var device: null

    readonly property bool polaczone: device !== null && device.connected
    readonly property bool wTrakcie: device !== null
        && (device.state === BluetoothDeviceState.Connecting
         || device.state === BluetoothDeviceState.Disconnecting)

    hoverEnabled: true
    active: polaczone

    implicitHeight: tresc.implicitHeight + 2 * Theme.spacingSm

    Item {
        id: tresc
        anchors.fill: parent
        anchors.margins: Theme.spacingSm
        implicitHeight: Math.max(glif.implicitHeight, teksty.implicitHeight, 24)

        Label {
            id: glif
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            font.pixelSize: Theme.fontSizeNormal + 2
            // BlueZ provides a freedesktop icon name (audio-headset,
            // input-mouse...). We have no icon theme in the panel, so
            // we show a single Bluetooth glyph, and the device type
            // is evident from its name right next to it anyway.
            text: root.polaczone ? Icons.bluetoothConnected : Icons.bluetoothOn
            color: root.polaczone ? Theme.accent : Theme.textMuted

            Behavior on color { ColorAnimation { duration: Theme.animNormal } }
        }

        Column {
            id: teksty
            anchors.left: glif.right
            anchors.leftMargin: Theme.spacingSm
            anchors.right: bateria.visible ? bateria.left : parent.right
            anchors.rightMargin: Theme.spacingSm
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Label {
                width: parent.width
                text: root.device === null ? "" : root.device.deviceName
                font.weight: root.polaczone ? Theme.fontWeightMedium
                                            : Theme.fontWeightNormal
                color: root.polaczone ? Theme.text : Theme.textMuted
            }

            Label {
                width: parent.width
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.iron
                text: {
                    if (root.device === null) return "";
                    if (root.device.pairing) return Tr.t("Pairing…", "Parowanie…");
                    switch (root.device.state) {
                        case BluetoothDeviceState.Connecting:    return Tr.t("Connecting…", "Łączenie…");
                        case BluetoothDeviceState.Disconnecting: return Tr.t("Disconnecting…", "Rozłączanie…");
                        case BluetoothDeviceState.Connected:     return Tr.t("Connected", "Połączone");
                    }
                    if (root.device.paired || root.device.bonded) return Tr.t("Paired", "Sparowane");
                    return Tr.t("New device", "Nowe urządzenie");
                }
            }
        }

        Label {
            id: bateria
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.device !== null && root.device.batteryAvailable
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Theme.fontWeightBold
            // Below 20% the ember color - the same readability threshold
            // as for the laptop battery.
            color: root.device !== null && root.device.battery <= 0.2
                ? Theme.ember : Theme.textMuted
            text: root.device === null
                ? ""
                : Math.round(root.device.battery * 100) + "%"
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !root.wTrakcie
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.device === null) return;
            if (root.device.connected) {
                root.device.disconnect();
                return;
            }
            // See "TRUSTED BEFORE PAIRING" in the header.
            if (!root.device.trusted) root.device.trusted = true;
            if (root.device.paired || root.device.bonded) {
                root.device.connect();
            } else {
                // BlueZ will not connect an unpaired device anyway,
                // so we pair - the connection usually follows on its own.
                root.device.pair();
            }
        }
    }
}
