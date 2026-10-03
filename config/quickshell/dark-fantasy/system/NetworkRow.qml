// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  A SINGLE WI-FI NETWORK IN THE LIST.
//
//  A click acts depending on what can be done with the network:
//      connected          -> disconnect
//      saved              -> connect (NetworkManager has the password)
//      open               -> connect
//      WPA/WPA2/WPA3 PSK  -> expand the password field
//      enterprise (EAP)   -> nothing; the row says nmtui is needed
//
//  ---------------------------------------------------------------
//  PASSWORD
//
//  The password field exists only while expanded, and it is
//  cleared on every collapse and right after sending. The typed
//  string goes nowhere except the connectWithPsk() call, which
//  hands it to NetworkManager - that is what stores the credentials.
//  The shell never writes it to any file nor logs it.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
// Qualified import - QtQuick.Controls has its own "Label" type,
// which with an unqualified import shadows our
// components/Label.qml. The symptom is misleading: text with an explicit
// "color:" looks fine, while text without one turns almost black, because
// Controls takes the color from Qt's default (light) palette - and
// font.family gets lost too.
import QtQuick.Controls.Basic as QC
// Qualified for the same reason as Controls above: the
// Quickshell.Networking module exports a TYPE named "Network", and our
// singleton from qs.services has the same name. With an unqualified
// import the module's type wins and every service call ends
// with "Property 'x' of object Quickshell.Networking/Network is not
// a function" - an error pointing at a foreign object, not ours.
import Quickshell.Networking as QN
import qs
import qs.components
import qs.services

Card {
    id: root

    // WifiNetwork object from Quickshell.Networking.
    property var network: null

    // Whether this row has its password field expanded. The section above
    // holds this, so that two rows cannot be expanded at once.
    property bool expanded: false

    signal expandRequested()
    signal collapseRequested()

    readonly property bool polaczona: network !== null && network.connected
    readonly property bool wTrakcie: network !== null && network.stateChanging

    hoverEnabled: true
    active: polaczona

    implicitHeight: tresc.implicitHeight + 2 * Theme.spacingSm

    // Collapsing clears the password - there is no reason for the typed
    // string to outlive closing the field.
    onExpandedChanged: if (!expanded) pole.text = "";

    Column {
        id: tresc
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingSm
        spacing: Theme.spacingSm

        // ---------- ROW ----------
        Item {
            width: parent.width
            height: Math.max(glif.implicitHeight, teksty.implicitHeight, 24)

            Label {
                id: glif
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                font.pixelSize: Theme.fontSizeNormal + 2
                text: root.network === null
                    ? ""
                    : Icons.step(Icons.wifiSteps, root.network.signalStrength)
                color: root.polaczona ? Theme.accent : Theme.textMuted

                Behavior on color { ColorAnimation { duration: Theme.animNormal } }
            }

            Column {
                id: teksty
                anchors.left: glif.right
                anchors.leftMargin: Theme.spacingSm
                anchors.right: klodka.left
                anchors.rightMargin: Theme.spacingSm
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Label {
                    width: parent.width
                    text: root.network === null ? "" : root.network.name
                    font.weight: root.polaczona ? Theme.fontWeightMedium
                                                : Theme.fontWeightNormal
                    color: root.polaczona ? Theme.text : Theme.textMuted
                }

                Label {
                    width: parent.width
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.iron
                    text: {
                        if (root.network === null) return "";
                        if (root.wTrakcie) {
                            return root.network.state === QN.ConnectionState.Connecting
                                ? Tr.t("Connecting…", "Łączenie…")
                                : Tr.t("Disconnecting…", "Rozłączanie…");
                        }
                        if (root.polaczona) return Tr.t("Connected", "Połączona");
                        if (Network.wymagaMenedzera(root.network))
                            return Network.opisZabezpieczen(root.network)
                                 + Tr.t(" — requires nmtui", " — wymaga nmtui");
                        const opis = Network.opisZabezpieczen(root.network);
                        if (root.network.known)
                            return opis === "" ? Tr.t("Saved", "Zapamiętana")
                                               : opis + Tr.t(" · saved", " · zapamiętana");
                        return opis;
                    }
                }
            }

            // A padlock next to a network that requires something. An open
            // network does not get one - the missing padlock is information itself.
            Label {
                id: klodka
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: root.network !== null && !Network.otwarta(root.network)
                text: Icons.wifiLocked
                font.pixelSize: Theme.fontSizeNormal
                color: Theme.iron
            }
        }

        // ---------- PASSWORD FIELD ----------
        Item {
            width: parent.width
            visible: root.expanded
            height: visible ? 32 : 0

            Rectangle {
                anchors.fill: parent
                anchors.rightMargin: polacz.width + Theme.spacingSm
                radius: Theme.radiusSmall
                color: Qt.alpha(Theme.background, 0.6)
                border.width: Theme.borderWidth
                border.color: pole.activeFocus ? Theme.borderActive : Theme.border

                Behavior on border.color {
                    ColorAnimation { duration: Theme.animFast }
                }

                QC.TextField {
                    id: pole
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingSm
                    anchors.rightMargin: Theme.spacingSm

                    // The password is shown neither on screen nor in suggestions.
                    echoMode: TextInput.Password
                    passwordCharacter: "•"

                    placeholderText: Tr.t("Network password", "Hasło sieci")
                    placeholderTextColor: Theme.iron

                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    color: Theme.text
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.background

                    // Controls draws its own background - we remove it, because
                    // the frame is painted by the rectangle above.
                    background: null

                    onAccepted: root.wyslij()
                    // Esc gives up typing. Unhandled, it never reached the
                    // panel's key receiver, which is not a parent of the field.
                    Keys.onEscapePressed: {
                        pole.text = "";
                        root.collapseRequested();
                    }
                }
            }

            IconButton {
                id: polacz
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.wifiSteps[Icons.wifiSteps.length - 1]
                enabled: pole.text.length > 0
                onClicked: root.wyslij()
            }
        }
    }

    function wyslij() {
        if (pole.text.length === 0) return;
        Network.connectWithPsk(root.network, pole.text);
        // Clear immediately - NetworkManager already has the password.
        pole.text = "";
        root.collapseRequested();
    }

    MouseArea {
        anchors.fill: parent
        // An expanded row ignores clicks on the background - otherwise
        // a click in the password field would collapse it while typing.
        enabled: !root.expanded && !root.wTrakcie
        cursorShape: Network.wymagaMenedzera(root.network)
            ? Qt.ArrowCursor : Qt.PointingHandCursor

        onClicked: {
            if (root.network === null) return;

            if (root.network.connected) {
                Network.disconnect(root.network);
                return;
            }
            if (root.network.known || Network.otwarta(root.network)) {
                Network.connect(root.network);
                return;
            }
            if (Network.pskMozliwe(root.network)) {
                root.expandRequested();
                return;
            }
            // Enterprise network - the panel cannot configure it. The row's
            // subtitle says nmtui is needed; we do nothing.
        }
    }
}
