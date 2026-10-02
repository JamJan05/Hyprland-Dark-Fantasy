// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  A SINGLE NOTIFICATION.
//
//  The same component serves both the popup and the history entry -
//  they differ only in whether they disappear on their own. Thanks to that the popup
//  and its trace in the center look identical, rather than like two
//  different views of the same thing.
//
//  Layout modelled on the SwayNC notification card
//  (config/swaync/style.css): app icon, app name
//  dimmed at the top, bold title, body, and below it
//  the action buttons.
//
//  THE "default" ACTION IS NOT A BUTTON. Per the notification spec it is what
//  a click on the notification itself does (kitty uses it to bring up the
//  window that sent it), and it usually has no label - as a button it was an
//  empty square. So a click on the card invokes it, and only actions with a
//  label become buttons.
//
//  ---------------------------------------------------------------
//  THE BODY CAN BE HOSTILE
//
//  The "body" field comes from any application and may contain
//  Pango markup. QML renders StyledText as a subset of HTML,
//  so we treat it as FORMATTED text, but without links
//  and without images - hence bodyImagesSupported: false on the
//  server side. We do not declare capabilities we do not support.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications as QSN
import qs
import qs.components
import qs.services

Card {
    id: root

    // Notification object from Quickshell.Services.Notifications.
    property var notification: null

    // A popup disappears by itself after a while; a history entry waits.
    property bool ephemeral: false

    readonly property bool krytyczne: notification !== null
        && notification.urgency === QSN.NotificationUrgency.Critical

    hoverEnabled: true

    // A critical notification carries the ember colour in its frame - the same one
    // that says "warning" in this theme. SwayNC did the same
    // with the ".critical" rule.
    border.color: krytyczne ? Theme.ember : Theme.border

    implicitHeight: tresc.implicitHeight + 2 * Theme.spacingMd

    // ---------------------------------------------------------------
    //  POPUP COUNTDOWN
    //
    //  The time is chosen by the service, by urgency level and by the wish of the
    //  application itself. Zero means "do not disappear by yourself" - that is how
    //  critical notifications behave, so that nothing important is missed.
    //
    //  Hovering the mouse pauses the countdown: a popup has no right to
    //  disappear the moment someone reaches for its button.
    // ---------------------------------------------------------------
    readonly property int czas: Notifications.czasDlaPowiadomienia(notification)

    Timer {
        interval: root.czas * 1000
        running: root.ephemeral && root.czas > 0 && !root.hovered
        onTriggered: Notifications.hidePopup(root.notification)
    }

    readonly property var akcjaDomyslna: {
        if (notification === null) return null;
        for (const a of notification.actions) if (a.identifier === "default") return a;
        return null;
    }

    readonly property var przyciski: notification === null ? []
        : notification.actions.filter(a => a.identifier !== "default" && a.text !== "")

    // A click on the card = the default action. Declared before the content,
    // so the close button and the action buttons lie above it and keep
    // their own clicks.
    MouseArea {
        anchors.fill: parent
        enabled: root.akcjaDomyslna !== null
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifications.invoke(root.akcjaDomyslna, root.notification)
    }

    Column {
        id: tresc
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingMd
        spacing: Theme.spacingSm

        // ---------- HEAD ----------
        Item {
            width: parent.width
            height: Math.max(ikona.height, naglowki.implicitHeight)

            // App icon. The name from the icon theme is resolved
            // to a path; when the application provided none, the
            // Nerd Font bell remains.
            Item {
                id: ikona
                anchors.left: parent.left
                anchors.top: parent.top
                width: 28
                height: 28

                readonly property string sciezka: {
                    if (root.notification === null) return "";
                    const nazwa = root.notification.appIcon;
                    if (nazwa === "") return "";
                    // The spec also allows a file:// URI or an absolute path
                    // (notify-send -i /path/icon.png); iconPath only knows
                    // theme names and returned "" for those - the bell.
                    if (nazwa.startsWith("file://")) return nazwa;
                    if (nazwa.startsWith("/")) return "file://" + nazwa;
                    return Quickshell.iconPath(nazwa, true);
                }

                Image {
                    anchors.fill: parent
                    source: ikona.sciezka
                    visible: ikona.sciezka !== "" && status === Image.Ready
                    asynchronous: true
                    sourceSize.width: 28 * Screen.devicePixelRatio
                    sourceSize.height: 28 * Screen.devicePixelRatio
                }

                Label {
                    anchors.centerIn: parent
                    visible: ikona.sciezka === ""
                    text: Icons.dndOff              // bell
                    font.pixelSize: Theme.fontSizeIcon
                    color: root.krytyczne ? Theme.ember : Theme.iron
                }
            }

            Column {
                id: naglowki
                anchors.left: ikona.right
                anchors.leftMargin: Theme.spacingSm
                anchors.right: zamknij.left
                anchors.rightMargin: Theme.spacingXs
                anchors.top: parent.top
                spacing: 1

                Label {
                    width: parent.width
                    visible: text !== ""
                    text: root.notification === null ? "" : root.notification.appName
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.krytyczne ? Theme.ember : Theme.accent
                }

                Label {
                    width: parent.width
                    visible: text !== ""
                    text: root.notification === null ? "" : root.notification.summary
                    font.weight: Theme.fontWeightBold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }
            }

            IconButton {
                id: zamknij
                anchors.right: parent.right
                anchors.top: parent.top
                icon: "\u{f0156}"        // cross
                destructive: true
                accentColor: Theme.iron
                // The cross appears only under the cursor - otherwise
                // the list in the center would be a wall of crosses.
                opacity: root.hovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                onClicked: Notifications.dismiss(root.notification)
            }
        }

        // ---------- BODY ----------
        Label {
            width: parent.width
            visible: text !== ""
            // <img> tags are stripped: StyledText loads them, so a body
            // with <img src="http://..."> made the shell fetch the URL (a
            // tracking pixel) or read a local file. bodyImagesSupported:
            // false is only a hint to applications.
            text: root.notification === null ? ""
                : root.notification.body.replace(/<img\b[^>]*>/gi, "")
            color: Theme.textMuted
            wrapMode: Text.Wrap
            maximumLineCount: 6
            // Applications send the body with Pango markup. StyledText
            // understands a subset of it; RichText does not, and PlainText would show
            // a raw "<b>" in the text.
            textFormat: Text.StyledText
        }

        // ---------- ACTIONS ----------
        Flow {
            width: parent.width
            spacing: Theme.spacingSm
            visible: root.przyciski.length > 0

            Repeater {
                model: root.przyciski

                delegate: Rectangle {
                    id: przycisk
                    required property var modelData

                    implicitWidth: etykieta.implicitWidth + 2 * Theme.spacingMd
                    implicitHeight: 26
                    radius: Theme.radiusSmall

                    color: mysz.pressed ? Theme.pressWash
                         : mysz.containsMouse ? Qt.alpha(Theme.surfaceAlt, 0.95)
                                              : Qt.alpha(Theme.surfaceAlt, 0.45)

                    border.width: Theme.borderWidth
                    border.color: mysz.containsMouse ? Theme.borderActive
                                                     : Theme.border

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    Label {
                        id: etykieta
                        anchors.centerIn: parent
                        text: przycisk.modelData.text
                        font.pixelSize: Theme.fontSizeSmall
                        color: mysz.containsMouse ? Theme.accent : Theme.textMuted
                    }

                    MouseArea {
                        id: mysz
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.invoke(przycisk.modelData,
                                                        root.notification)
                    }
                }
            }
        }
    }
}
