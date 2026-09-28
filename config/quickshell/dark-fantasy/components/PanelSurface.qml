// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  PANEL SURFACE - background, border, shadow and opening animation.
//
//  Common base for MediaPanel, the quick panel (QuickPanel)
//  and the OSD. Thanks to it all three open identically and share
//  the same outline - this is the part that makes the panels
//  read as one system rather than three bolted-on widgets.
//
//  ---------------------------------------------------------------
//  WHY THE WINDOW LIVES ALL THE TIME
//
//  A Quickshell panel is a layer-shell surface. If it were created
//  and destroyed on every open, HYPRLAND would animate it with the
//  "layersIn/layersOut" rule from hyprland.lua - and our QML animation
//  would overlap with that one. Two motions at once always look bad.
//
//  So the window is visible from shell startup, and opening
//  and closing happen entirely here. So that a closed panel
//  does not catch clicks, the window sets an empty input mask
//  (a zero-size Region) - see media/MediaPanel.qml.
//
//  ---------------------------------------------------------------
//  WHERE THE DURATIONS AND CURVE COME FROM
//
//  From config/hypr/hyprland.lua, leaf "layers":
//      layersIn   speed 4    bezier easeOutQuint  -> 400 ms
//      layersOut  speed 1.5  bezier linear        -> 150 ms
//
//  The entrance is ~2.5x slower than the exit, and that is no accident:
//  opening should be soft, closing immediate. We keep
//  this asymmetry so the panel behaves like the rest of the environment.
//
//  FADE ONLY.
//
//  No scaling and no slide from under the bar: in Dark Souls style a panel
//  emerges from darkness rather than popping out - the same as the windows,
//  which only fade ("popin 100%" in hyprland.lua). An offset is still possible
//  (slideDistance) - zero by default; the OSD uses Theme.driftDistance, same
//  as notification popups.
//
//  Grain lies under the card's content (components/Szum.qml) - "ash,
//  not smooth black".
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs

Item {
    id: root

    // The only control input. Set to true to open the panel.
    property bool open: false

    // Animation progress 0.0 - 1.0. Panels read it to know
    // whether clicking is possible yet (see the window's input mask).
    readonly property real progress: postep

    // How many pixels the panel slides down when opening. Zero by default -
    // see "FADE ONLY" in the header. Negative value = upwards.
    property int slideDistance: 0

    // PANEL ATTACHED TO THE BAR.
    //
    // true = the panel touches Waybar with its top edge and should look
    // like it slides out OF it, not like a separate window hanging below.
    // This changes three things at once:
    //
    //   1. the top corners are squared off - rounded corners at the joint
    //      would read as "this is a separate card";
    //   2. the shadow does not extend above the top edge - otherwise
    //      it would darken the bar the panel hangs under (the Quickshell
    //      layer is created AFTER Waybar, so it lies above it);
    //   3. the caller should zero slideDistance, because a downward slide
    //      would mean the panel is drawn ABOVE the bar at the start
    //      of the animation.
    property bool attachedTop: false

    // How far the shadow sticks out past the card's outline.
    readonly property int zapasCienia: Theme.shadowBlur + Theme.shadowOffsetY

    // Everything the caller puts into PanelSurface lands inside
    // the card - not next to it.
    default property alias content: contentItem.data

    // Distance from the panel's edge to its content.
    property int padding: Theme.spacingLg

    // Card background alpha. Panel alpha by default; the app menu uses a lighter one -
    // see Theme.menuOpacity.
    property real surfaceOpacity: Theme.panelOpacity

    // Signal emitted when the closing animation finishes.
    // The panel can then e.g. release resources.
    signal closed()

    // ---------------------------------------------------------------
    //  ANIMATION
    // ---------------------------------------------------------------
    property real postep: open ? 1.0 : 0.0

    Behavior on postep {
        NumberAnimation {
            // Duration and curve depend on DIRECTION. At the moment the
            // Behavior starts, "open" already has its target value, so it is
            // enough to read them from it.
            duration: root.open ? Theme.animPanelIn : Theme.animPanelOut
            easing.type: root.open ? Easing.Bezier : Easing.Linear
            easing.bezierCurve: Theme.easeOutQuint
        }
    }

    onPostepChanged: if (postep === 0.0 && !open) root.closed()

    implicitWidth: karta.implicitWidth
    implicitHeight: karta.implicitHeight

    // ---------------------------------------------------------------
    //  SHADOW - under the card, so declared before it.
    //
    //  It sits in a container that, for a panel attached to the bar,
    //  clips it to the card's top edge. Without that the shadow would spill
    //  onto the bar and darken its right end.
    // ---------------------------------------------------------------
    Item {
        anchors.fill: karta
        anchors.leftMargin: -root.zapasCienia
        anchors.rightMargin: -root.zapasCienia
        anchors.bottomMargin: -root.zapasCienia
        anchors.topMargin: root.attachedTop ? 0 : -root.zapasCienia

        clip: root.attachedTop
        opacity: root.postep

        DropShadow {
            x: root.zapasCienia
            y: root.attachedTop ? 0 : root.zapasCienia
            width: karta.width
            height: karta.height
            radius: karta.radius
        }
    }

    // ---------------------------------------------------------------
    //  CARD
    // ---------------------------------------------------------------
    Rectangle {
        id: karta

        anchors.fill: parent
        radius: Theme.radiusLarge

        // Corners where the panel meets the bar are squared off. Qt 6.7 introduced
        // per-corner radii, so no tricks with an overlaid
        // rectangle are needed.
        topLeftRadius: root.attachedTop ? 0 : radius
        topRightRadius: root.attachedTop ? 0 : radius

        // Alpha .96, not .88 like the bar. The panel is large, dense with text
        // and sits above windows - it is in the audio panel's category, not the bar's.
        // Blurring what is underneath is done by the layer rule
        // in hyprland.lua, not this file.
        color: Qt.alpha(Theme.background, root.surfaceOpacity)

        border.width: Theme.borderWidth
        border.color: Theme.border

        implicitWidth: contentItem.implicitWidth + 2 * root.padding
        implicitHeight: contentItem.implicitHeight + 2 * root.padding

        // The content is clipped to the rounded corners - without this
        // a long list would stick out past the card's outline during the slide.
        clip: true

        // CLICK EATER.
        //
        // The panel lies on a fullscreen window whose job is to
        // catch clicks NEXT TO the panel and close it. Without this layer
        // a click on an empty spot of the card ITSELF - next to a slider, between
        // sections - would fall straight through to that catcher
        // and close the very panel being aimed at.
        //
        // Declared BEFORE the content, so it lies beneath it: sliders
        // and buttons get events first, and only what nobody handled
        // lands here.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        // Grain under the content, above the background color. Inset by the border width,
        // so it does not dim the gold outline.
        Szum {
            anchors.fill: parent
            anchors.margins: Theme.borderWidth
        }

        Item {
            id: contentItem
            anchors.fill: parent
            anchors.margins: root.padding
        }
    }

    // ---------------------------------------------------------------
    //  OPENING TRANSFORMS
    // ---------------------------------------------------------------
    opacity: postep


    // The downward slide is done with a transform, NOT by setting "y".
    // The panel is anchored to the window's top edge, and writing to "y"
    // with active anchors is ignored by QML (with a warning
    // in the log). Translate works independently of layout.
    transform: Translate {
        y: -root.slideDistance * (1.0 - root.postep)
    }
}
