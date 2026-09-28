// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  OSD - a brief preview when volume, brightness or the
//  power profile changes, and on mute.
//
//  Waybar has no volume or brightness modules, so the XF86Audio* and
//  XF86MonBrightness* keys (handled by hyprland.lua) would give no
//  confirmation on screen. This is that confirmation.
//
//  ---------------------------------------------------------------
//  THERE IS NO SECOND SOURCE OF VOLUME HERE
//
//  The OSD does not run wpctl, does not read sysfs and does not poll anything.
//  It reads the same singletons as the panel: services/Audio.qml
//  and services/Brightness.qml. Both are reactive, so the OSD learns
//  about a change at the same moment as the panel - and shows exactly
//  the same number. A mismatch like "OSD says 40%, panel 45%" is
//  structurally impossible here.
//
//  The hardware key still calls wpctl and brightnessctl from hyprland.lua.
//  We do not intercept that - we simply see the effect: PipeWire
//  reports the change over D-Bus, and brightness arrives as a sysfs event.
//
//  The power profile likewise: SUPER+B only switches PowerProfiles,
//  and the OSD reacts to the change - so it also confirms a change made from the Cogwheel
//  and from powerprofilesctl in a terminal.
//
//  ---------------------------------------------------------------
//  WHAT THE OSD DOES NOT SHOW
//
//  1. At shell startup. The first values arrive from PipeWire
//     and sysfs a few dozen milliseconds after launch and look
//     like a "change" to QML. Without a lock the OSD would blink after every
//     login and after every configuration reload.
//  2. When the Cogwheel is open. It then shows
//     the same sliders live, so the OSD would only cover the screen,
//     repeating information that is visible anyway.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs
import qs.components
import qs.services

PanelWindow {
    id: root

    // Set by shell.qml. With a panel open the OSD stays silent.
    property bool suppressed: false

    // What we show: "glosnosc" | "mikrofon" | "jasnosc" | "profil".
    property string rodzaj: ""

    property bool widoczny: false

    WlrLayershell.namespace: "quickshell-osd"

    // Overlay, not Top - the OSD must be visible also above a fullscreen
    // window. For exactly the same reason the SwayNC popups
    // sit on the "overlay" layer (see swaync/config.json).
    WlrLayershell.layer: WlrLayer.Overlay

    // The OSD accepts nothing from the keyboard.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Bottom of the screen, centred. When anchored to only one
    // edge, the layer-shell protocol centres the surface on the other axis by itself.
    //
    // A 150 px offset from the bottom clears the tile row: 76 px tile,
    // 18 px margin and the selected tile's name above it - otherwise the OSD
    // would land on the name. (With the dock 120 was enough.)
    anchors.bottom: true
    margins.bottom: 150

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: true

    // Room for the shadow sticking out beyond the card outline.
    readonly property int zapasNaCien: Theme.shadowBlur + Theme.shadowOffsetY

    implicitWidth: 320 + 2 * zapasNaCien
    implicitHeight: powierzchnia.implicitHeight + 2 * zapasNaCien

    // The OSD is for looking only. An empty mask lets the mouse
    // pass straight through it - otherwise it would block clicks
    // in the window underneath for that second and a half.
    mask: Region {
        width: 0
        height: 0
    }

    // ---------------------------------------------------------------
    //  WHEN TO SHOW
    // ---------------------------------------------------------------
    property bool gotowy: false

    Timer {
        // Startup lock - see point 1 in the header. A second is comfortably
        // enough: PipeWire and FileView deliver their first values
        // within a few dozen milliseconds.
        interval: 1000
        running: true
        onTriggered: root.gotowy = true
    }

    Timer {
        id: odliczanie
        // 1.5 s. Shorter than the shortest SwayNC popup (timeout-low: 4 s),
        // because the OSD carries no text to read - only a number,
        // which you check at a glance.
        interval: 1500
        onTriggered: root.widoczny = false
    }

    function pokaz(co: string) {
        if (!gotowy || suppressed) return;
        rodzaj = co;
        widoczny = true;
        odliczanie.restart();
    }

    // When a panel opens we hide the OSD immediately, without waiting for
    // the countdown - otherwise it would hang for a moment above the freshly opened
    // panel, showing the same thing as the panel.
    onSuppressedChanged: if (suppressed) widoczny = false;

    Connections {
        target: Audio
        function onVolumeChanged() { root.pokaz("glosnosc"); }
        function onMutedChanged() { root.pokaz("glosnosc"); }
        function onMicVolumeChanged() { root.pokaz("mikrofon"); }
        function onMicMutedChanged() { root.pokaz("mikrofon"); }
    }

    Connections {
        target: Brightness
        function onValueChanged() { root.pokaz("jasnosc"); }
    }

    Connections {
        target: PowerProfiles
        function onProfileChanged() { root.pokaz("profil"); }
    }

    readonly property string nazwaProfilu:
        PowerProfiles.profile === PowerProfile.PowerSaver  ? Tr.t("power saver", "oszczędny")
      : PowerProfiles.profile === PowerProfile.Performance ? Tr.t("performance", "wydajność")
                                                            : Tr.t("balanced", "zrównoważony")

    // ---------------------------------------------------------------
    //  WHAT TO SHOW
    // ---------------------------------------------------------------
    readonly property bool wyciszone:
        rodzaj === "glosnosc" ? Audio.muted
      : rodzaj === "mikrofon" ? Audio.micMuted
                              : false

    readonly property real wartosc:
        rodzaj === "glosnosc" ? Audio.volume
      : rodzaj === "mikrofon" ? Audio.micVolume
      : rodzaj === "jasnosc"  ? Brightness.value
                              : 0

    readonly property string etykieta:
        rodzaj === "glosnosc" ? Tr.t("Volume", "Głośność")
      : rodzaj === "mikrofon" ? Tr.t("Microphone", "Mikrofon")
      : rodzaj === "jasnosc"  ? Tr.t("Brightness", "Jasność")
      : rodzaj === "profil"   ? Tr.t("Power profile", "Profil zasilania")
                              : ""

    readonly property string glif: {
        if (rodzaj === "mikrofon")
            return wyciszone ? Icons.microphoneMuted : Icons.microphone;
        if (rodzaj === "jasnosc")
            return Icons.step(Icons.brightnessSteps, wartosc);
        if (rodzaj === "profil")
            return PowerProfiles.profile === PowerProfile.PowerSaver ? Icons.profileSaver
                 : PowerProfiles.profile === PowerProfile.Performance ? Icons.profilePerformance
                                                                       : Icons.profileBalanced;
        return wyciszone ? Icons.volumeMuted
                         : Icons.step(Icons.volumeSteps, wartosc);
    }

    PanelSurface {
        id: powierzchnia

        anchors.centerIn: parent
        width: 320
        implicitHeight: rzad.implicitHeight + 2 * padding

        padding: Theme.spacingMd + 2

        open: root.widoczny

        // The OSD drifts by the same amount as a notification popup - a negative
        // value means movement UPWARD.
        slideDistance: -Theme.driftDistance

        Item {
            id: rzad
            anchors.fill: parent
            implicitHeight: Math.max(ikona.implicitHeight, opis.implicitHeight)

            Label {
                id: ikona
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                font.pixelSize: Theme.fontSizeIcon + 4
                text: root.glif
                color: root.wyciszone ? Theme.ember : Theme.accent

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            Column {
                id: opis
                anchors.left: ikona.right
                anchors.leftMargin: Theme.spacingSm
                anchors.right: procent.left
                anchors.rightMargin: Theme.spacingSm
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingSm

                Label {
                    width: parent.width
                    text: root.etykieta
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textMuted
                }

                // No bar for the power profile: the profile name next to it varies
                // in length, so the bar would change width on every switch - and
                // the name tells the level anyway.
                ProgressBar {
                    width: parent.width
                    visible: root.rodzaj !== "profil"
                    value: root.wartosc
                    muted: root.wyciszone
                }
            }

            Label {
                id: procent
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                // The profile name is longer than "100%" - it gets as much
                // room as it needs, at the expense of the bar.
                // Math.max: the English "muted" can be wider than 42 px.
                width: root.rodzaj === "profil" ? implicitWidth : Math.max(42, implicitWidth)
                horizontalAlignment: Text.AlignRight
                font.weight: Theme.fontWeightBold
                color: root.wyciszone ? Theme.ember : Theme.text
                // Mute is stated with a word, not a zero - the volume does not
                // have to be zero then, and "0%" would suggest that it is.
                text: root.wyciszone ? Tr.t("muted", "wyc.")
                    : root.rodzaj === "profil" ? root.nazwaProfilu
                    : Math.round(root.wartosc * 100) + "%"
            }
        }
    }
}
