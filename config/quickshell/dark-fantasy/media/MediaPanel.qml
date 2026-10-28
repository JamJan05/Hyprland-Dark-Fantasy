// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  MEDIA PANEL - the player, opened from the "now" frame on the bar
//  or with SUPER+O.
//
//  Same language as the rest of the interface: a sharp stone slab with
//  grain and a faded gold border, a small-caps header, the cover as an
//  "item" (desaturated, vignetted), progress as the 6 px HUD bar and
//  bare glyphs instead of pill buttons. It only fades - no sliding.
//
//  Keys: Left/Right - previous/next, Enter or Space - play/pause,
//  Up/Down - volume, S - shuffle, R - repeat (track / playlist / off),
//  Esc - close. Clicking outside the slab closes it too.
//
//  The volume bar is the SYSTEM output (services/Audio.qml), the same
//  number the OSD and the Cogwheel show - not the player's own MPRIS
//  volume, which browsers rarely support and Spotify keeps separate
//  from the sink, so the two would drift apart.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import qs
import qs.components
import qs.services

PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    WlrLayershell.namespace: "quickshell-media"
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

    // Closed = empty input mask, so the window never eats clicks.
    mask: Region {
        x: 0
        y: Theme.panelMarginTop
        width: root.open ? root.width : 0
        height: root.open ? root.height - Theme.panelMarginTop : 0
    }

    readonly property var gracz: Player.active
    readonly property bool jest: gracz !== null

    readonly property int margines: Theme.spacingLg

    // 5 % - the same step as the volume keys in hyprland.lua and the
    // Cogwheel slider.
    readonly property real krokGlosnosci: 0.05

    Item {
        anchors.fill: parent
        focus: root.open

        Keys.onPressed: function (zdarzenie) {
            switch (zdarzenie.key) {
            case Qt.Key_Escape:
                root.closeRequested();
                break;
            case Qt.Key_Left:
                if (root.jest && root.gracz.canGoPrevious) Player.previous();
                break;
            case Qt.Key_Right:
                if (root.jest && root.gracz.canGoNext) Player.next();
                break;
            case Qt.Key_Space:
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (root.jest && root.gracz.canTogglePlaying) Player.toggle();
                break;
            // Volume may auto-repeat (a held key is one smooth motion);
            // the toggles must not, or holding S would flicker.
            case Qt.Key_Up:
                Audio.setVolume(Audio.volume + root.krokGlosnosci);
                break;
            case Qt.Key_Down:
                Audio.setVolume(Audio.volume - root.krokGlosnosci);
                break;
            case Qt.Key_S:
                if (zdarzenie.isAutoRepeat) break;
                Player.toggleShuffle();
                break;
            case Qt.Key_R:
                if (zdarzenie.isAutoRepeat) break;
                Player.cycleLoop();
                break;
            default:
                return;
            }
            zdarzenie.accepted = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.open
        onClicked: root.closeRequested()
    }

    // MPRIS does not announce position changes while playing - ask once
    // a second, and only while the panel is actually visible.
    Timer {
        interval: 1000
        repeat: true
        running: root.open && Player.playing && root.jest
        onTriggered: root.gracz.positionChanged()
    }

    function czas(sekundy: real): string {
        if (!isFinite(sekundy) || sekundy < 0) return "0:00";
        const calk = Math.floor(sekundy);
        const s = calk % 60;
        const m = Math.floor(calk / 60) % 60;
        const h = Math.floor(calk / 3600);
        const ss = s < 10 ? "0" + s : "" + s;
        if (h > 0) return h + ":" + (m < 10 ? "0" + m : "" + m) + ":" + ss;
        return m + ":" + ss;
    }

    // A bare glyph: iron when unavailable, muted at rest, gold under the
    // cursor. The middle one (play/pause) is larger and brighter.
    //
    // "wlaczony" is for the toggles (shuffle, repeat): gold at rest when
    // on, and under the cursor the brighter text color, so an "on" glyph
    // still reacts to hovering. "maly" shrinks the glyph, not the hit box.
    component Glif: Item {
        id: glif

        property string znak: ""
        property bool duzy: false
        property bool maly: false
        property bool dostepny: true
        property bool wlaczony: false
        signal uzyty()

        implicitWidth: duzy ? 48 : 36
        implicitHeight: 44
        opacity: dostepny ? 1 : Theme.disabledOpacity

        Label {
            anchors.centerIn: parent
            text: glif.znak
            font.pixelSize: glif.duzy ? 30 : glif.maly ? 16 : 20
            color: !glif.dostepny ? Theme.iron
                 : myszGlifu.containsMouse ? (glif.wlaczony ? Theme.text : Theme.accent)
                 : glif.wlaczony ? Theme.accent
                 : glif.duzy ? Theme.text : Theme.textMuted

            Behavior on color { ColorAnimation { duration: Theme.animNormal } }
        }

        MouseArea {
            id: myszGlifu
            anchors.fill: parent
            hoverEnabled: true
            enabled: glif.dostepny
            cursorShape: Qt.PointingHandCursor
            onClicked: glif.uzyty()
        }
    }

    Item {
        id: plyta

        anchors.top: parent.top
        anchors.topMargin: Theme.panelMarginTop + Theme.spacingSm
        anchors.horizontalCenter: parent.horizontalCenter

        width: 460
        height: tresc.implicitHeight + 2 * root.margines

        opacity: root.open ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.open ? Theme.animPanelIn : Theme.animPanelOut
                easing.type: Easing.Bezier
                easing.bezierCurve: Theme.easeOutQuint
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Theme.background, Theme.panelOpacity)
            border.width: Theme.borderWidth
            border.color: Theme.border

            // Clicks on the slab must not reach the "click outside" catcher.
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Szum {
                anchors.fill: parent
                anchors.margins: Theme.borderWidth
            }
        }

        Column {
            id: tresc

            x: root.margines
            y: root.margines
            width: plyta.width - 2 * root.margines
            spacing: Theme.spacingSm

            Item {
                width: parent.width
                height: naglowek.implicitHeight

                Tytul {
                    id: naglowek
                    anchors.left: parent.left
                    text: Tr.t("Now playing", "Teraz gra")
                }

                Text {
                    anchors.right: parent.right
                    anchors.baseline: naglowek.baseline
                    width: Math.min(implicitWidth, parent.width - naglowek.implicitWidth - Theme.spacingLg)
                    visible: root.jest
                    text: Player.name
                    elide: Text.ElideRight
                    font.family: Theme.fontDisplay
                    font.pixelSize: Theme.fontSizeNormal
                    font.capitalization: Font.SmallCaps
                    font.letterSpacing: Theme.displayLetterSpacing
                    color: Theme.iron
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
            }

            Text {
                width: parent.width
                visible: !root.jest
                topPadding: Theme.spacingLg
                bottomPadding: Theme.spacingLg
                horizontalAlignment: Text.AlignHCenter
                text: Tr.t("Silence. Nothing is playing.", "Cisza. Nic nie gra.")
                font.family: Theme.fontDisplay
                font.pixelSize: Theme.fontSizeLarge + 2
                font.italic: true
                color: Theme.textMuted
            }

            // Cover on the left, the "item description" on the right.
            Item {
                width: parent.width
                height: visible ? Math.max(okladka.height, opisy.implicitHeight) + Theme.spacingSm : 0
                visible: root.jest

                AlbumArt {
                    id: okladka
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: Theme.spacingSm
                    width: 112
                    height: 112
                    source: root.jest ? root.gracz.trackArtUrl : ""
                }

                Column {
                    id: opisy
                    anchors.left: okladka.right
                    anchors.leftMargin: Theme.spacingLg
                    anchors.right: parent.right
                    anchors.top: okladka.top
                    spacing: Theme.spacingXs

                    Text {
                        width: parent.width
                        text: !root.jest ? ""
                            : root.gracz.trackTitle !== "" ? root.gracz.trackTitle
                            : Tr.t("Unknown track", "Nieznany utwór")
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.fontSizeLarge + 5
                        font.capitalization: Font.SmallCaps
                        font.features: { "lnum": 1 }
                        font.letterSpacing: Theme.displayLetterSpacing
                        color: Player.playing ? Theme.text : Theme.textMuted

                        Behavior on color { ColorAnimation { duration: Theme.animNormal } }
                    }

                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: root.jest ? root.gracz.trackArtist : ""
                        elide: Text.ElideRight
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.fontSizeLarge
                        font.capitalization: Font.SmallCaps
                        font.letterSpacing: Theme.displayLetterSpacing
                        color: Theme.textMuted
                    }

                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: root.jest ? root.gracz.trackAlbum : ""
                        elide: Text.ElideRight
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.fontSizeNormal + 1
                        font.italic: true
                        color: Theme.iron
                    }
                }
            }

            Item {
                id: postep

                width: parent.width
                visible: root.jest && root.gracz.lengthSupported
                height: visible ? pasek.height + czasy.height + Theme.spacingSm + Theme.spacingXs : 0

                readonly property real dlugosc: root.jest ? root.gracz.length : 0
                readonly property real pozycja: root.jest ? root.gracz.position : 0
                readonly property bool przewijalny:
                    root.jest && root.gracz.canSeek && root.gracz.positionSupported

                StatBar {
                    id: pasek
                    y: Theme.spacingSm
                    width: parent.width
                    length: parent.width
                    fillColor: Theme.accent
                    value: postep.dlugosc > 0 ? postep.pozycja / postep.dlugosc : 0
                }

                MouseArea {
                    anchors.fill: pasek
                    anchors.topMargin: -8
                    anchors.bottomMargin: -8
                    enabled: postep.przewijalny
                    cursorShape: postep.przewijalny ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: function (zdarzenie) {
                        const udzial = Math.max(0, Math.min(1, zdarzenie.x / width));
                        Player.seekTo(udzial * postep.dlugosc);
                    }
                }

                Item {
                    id: czasy
                    anchors.top: pasek.bottom
                    anchors.topMargin: Theme.spacingXs
                    width: parent.width
                    height: uplynelo.implicitHeight

                    Label {
                        id: uplynelo
                        anchors.left: parent.left
                        text: root.czas(postep.pozycja)
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textMuted
                    }

                    Label {
                        anchors.right: parent.right
                        text: root.czas(postep.dlugosc)
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.iron
                    }
                }
            }

            Item {
                width: parent.width
                height: visible ? 48 : 0
                visible: root.jest

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingLg

                    // Shuffle on the far left, repeat on the far right - the
                    // transport stays in the middle, where the hand expects it.
                    Glif {
                        anchors.verticalCenter: parent.verticalCenter
                        maly: true
                        znak: Icons.mediaShuffle
                        dostepny: Player.shuffleSupported
                        wlaczony: Player.shuffle
                        onUzyty: Player.toggleShuffle()
                    }

                    Glif {
                        anchors.verticalCenter: parent.verticalCenter
                        znak: Icons.mediaPrevious
                        dostepny: root.jest && root.gracz.canGoPrevious
                        onUzyty: Player.previous()
                    }

                    Glif {
                        anchors.verticalCenter: parent.verticalCenter
                        duzy: true
                        znak: Player.playing ? Icons.mediaPause : Icons.mediaPlay
                        dostepny: root.jest && root.gracz.canTogglePlaying
                        onUzyty: Player.toggle()
                    }

                    Glif {
                        anchors.verticalCenter: parent.verticalCenter
                        znak: Icons.mediaNext
                        dostepny: root.jest && root.gracz.canGoNext
                        onUzyty: Player.next()
                    }

                    // One glyph, three states: off (muted), the playlist
                    // (gold), this track (gold, with the "1").
                    Glif {
                        anchors.verticalCenter: parent.verticalCenter
                        maly: true
                        znak: Player.loopState === MprisLoopState.Track
                            ? Icons.mediaRepeatOnce : Icons.mediaRepeat
                        dostepny: Player.loopSupported
                        wlaczony: Player.loopState !== MprisLoopState.None
                        onUzyty: Player.cycleLoop()
                    }
                }
            }

            // Volume: speaker glyph (click = mute), the HUD bar, percentage.
            Item {
                id: glosnosc

                width: parent.width
                height: visible ? 32 : 0
                visible: root.jest

                readonly property bool dostepna: Audio.sinkReady
                readonly property int procent: Math.round(Audio.volume * 100)

                Glif {
                    id: glosnik
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 28
                    implicitHeight: 32
                    maly: true
                    znak: Audio.muted ? Icons.volumeMuted
                        : Icons.volumeSteps[Audio.volume < 0.34 ? 0 : Audio.volume < 0.67 ? 1 : 2]
                    dostepny: glosnosc.dostepna
                    wlaczony: !Audio.muted
                    onUzyty: Audio.toggleMute()
                }

                StatBar {
                    id: pasekGlosnosci
                    anchors.left: glosnik.right
                    anchors.leftMargin: Theme.spacingSm
                    anchors.right: procenty.left
                    anchors.rightMargin: Theme.spacingMd
                    anchors.verticalCenter: parent.verticalCenter
                    length: width
                    value: Audio.volume
                    fillColor: Audio.muted ? Theme.iron : Theme.accent
                    opacity: glosnosc.dostepna ? 1 : Theme.disabledOpacity
                }

                // Press or drag sets the level from the x position; the wheel
                // moves by one step. Only the vertical hit area is enlarged,
                // so x maps straight onto the bar.
                MouseArea {
                    anchors.fill: pasekGlosnosci
                    anchors.topMargin: -8
                    anchors.bottomMargin: -8
                    enabled: glosnosc.dostepna
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                    function ustaw(x: real) {
                        if (width <= 0) return;
                        Audio.setVolume(Math.max(0, Math.min(1, x / width)));
                    }

                    onPressed: function (zdarzenie) { ustaw(zdarzenie.x); }
                    onPositionChanged: function (zdarzenie) { if (pressed) ustaw(zdarzenie.x); }
                    onWheel: function (zdarzenie) {
                        const kroki = zdarzenie.angleDelta.y / 120;
                        if (kroki !== 0) Audio.setVolume(Audio.volume + kroki * root.krokGlosnosci);
                        zdarzenie.accepted = true;
                    }
                }

                Label {
                    id: procenty
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    horizontalAlignment: Text.AlignRight
                    text: glosnosc.dostepna ? glosnosc.procent + " %" : "—"
                    font.pixelSize: Theme.fontSizeSmall
                    font.features: { "tnum": 1 }
                    color: Audio.muted ? Theme.iron : Theme.textMuted
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
                visible: root.jest
            }

            Label {
                width: parent.width
                visible: root.jest
                topPadding: Theme.spacingXs
                horizontalAlignment: Text.AlignRight
                wrapMode: Text.Wrap
                text: Tr.t("← →  track      ↑ ↓  volume      Enter  play / pause\nS  shuffle      R  repeat      Esc  close",
                           "← →  utwór      ↑ ↓  głośność      Enter  graj / pauza\nS  losowo      R  powtórz      Esc  zamknij")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.iron
            }
        }
    }
}
