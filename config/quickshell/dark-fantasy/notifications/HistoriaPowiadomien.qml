pragma ComponentBehavior: Bound

// Pragma on the first line, before the comment - reason in Icons.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  NOTIFICATION HISTORY - header with "Clear", "do not disturb"
//  and the card list.
//
//  Shown above the tile row, in the Tidings tile (kafle/Wiesci.qml).
//
//  THERE IS NO GROUPING AND THAT IS A DECISION
//
//  SwayNC grouped notifications by application. Quickshell does not
//  provide it, so it would have to be written - and the value is doubtful for
//  a list that is read from the top anyway and cleared in bulk. Should it
//  start to chafe, grouping gets added here: just replace the
//  Repeater with a model grouped by notification.appName.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs
import qs.components
import qs.services

Column {
    id: root

    property string tytul: Tr.t("Notifications", "Powiadomienia")

    spacing: Theme.spacingMd

    // ---------- HEADER ----------
    Item {
        width: parent.width
        height: naglowek.implicitHeight

        Tytul {
            id: naglowek
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.tytul
        }

        // "Clear" disappears when there is nothing to clear - a button that does
        // nothing is worse than no button.
        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: Notifications.count > 0

            implicitWidth: wyczysc.implicitWidth + 2 * Theme.spacingMd
            height: 24
            radius: Theme.radiusSmall

            color: myszCzysc.pressed ? Theme.pressWash
                 : myszCzysc.containsMouse ? Theme.emberWash
                                           : "transparent"

            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Label {
                id: wyczysc
                anchors.centerIn: parent
                text: Tr.t("Clear", "Wyczyść")
                font.pixelSize: Theme.fontSizeSmall
                color: myszCzysc.containsMouse ? Theme.ember : Theme.textMuted
            }

            MouseArea {
                id: myszCzysc
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.clearAll()
            }
        }
    }

    // ---------- DO NOT DISTURB ----------
    ToggleRow {
        width: parent.width
        icon: Notifications.dnd ? Icons.dndOn : Icons.dndOff
        title: Tr.t("Do not disturb", "Nie przeszkadzać")
        checked: Notifications.dnd
        activeColor: Theme.ember
        subtitle: Notifications.dnd
            ? Tr.t("Popups silenced, history still kept", "Dymki wyciszone, historia działa")
            : Tr.t("Popups visible", "Dymki widoczne")
        onToggled: Notifications.toggleDnd()
    }

    // ---------- HISTORY ----------
    Label {
        width: parent.width
        visible: Notifications.count === 0
        horizontalAlignment: Text.AlignHCenter
        topPadding: Theme.spacingLg
        bottomPadding: Theme.spacingLg
        font.family: Theme.fontDisplay
        font.pixelSize: Theme.fontSizeLarge
        font.italic: true
        color: Theme.iron
        // Text carried over directly from SwayNC ("text-empty"),
        // because it was yours and fits the rest of the theme.
        text: Tr.t("Silence. The flame has dimmed.", "Cisza. Płomień przygasł.")
    }

    Column {
        width: parent.width
        spacing: Theme.spacingSm

        Repeater {
            model: Notifications.history

            delegate: NotificationCard {
                required property var modelData
                width: parent.width
                notification: modelData
                ephemeral: false
            }
        }
    }
}
