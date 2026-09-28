// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  SHADOW UNDER A PANEL.
//
//  QtQuick has no CSS box-shadow, and the repository uses it
//  in three places:
//      dock   #box             0 4px  14px rgba(6,6,7,.55)
//      swaync .control-center  0 8px  24px rgba(6,6,7,.65)
//      drawer window           0 10px 32px rgba(10,6,4,.72)
//  All on the same near-black #060607 - exactly the one
//  Hyprland shades windows with (decoration.shadow.color = 0xcc060607).
//
//  WHY NOT MultiEffect:
//  MultiEffect does a real Gaussian blur, but requires passing
//  the source through a texture. The panel is entirely 11-15 px
//  text; going through ShaderEffectSource softens the letters
//  enough to see a difference against the bar right next to it. A shadow is not worth that.
//
//  Instead we stack several filled rectangles of increasing
//  size and low alpha. Overlapping, they give a soft falloff of
//  brightness towards the edges. The element we put this under covers
//  the middle of the stack, so only what sticks out past its outline is visible.
//
//  USAGE - always BEFORE the shaded element, i.e. beneath it:
//      first DropShadow with anchors.fill and radius matching the shaded
//      card, right after it the card itself - order matters, because QML
//      draws siblings in declaration order.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

// Repeater delegates reach for identifiers from the enclosing file
// (root). Without this pragma Qt 6 binds them lazily and warns
// that they may fail to resolve in a different context.
pragma ComponentBehavior: Bound

import QtQuick
import qs

Item {
    id: root

    // Corner radius of the element the shadow is placed under.
    property int radius: Theme.radiusLarge

    // Spread - how many pixels the shadow sticks out past the outline.
    property int spread: Theme.shadowBlur

    // Downward offset. The shadow falls from above, as in all
    // three rules from the repository.
    property int offsetY: Theme.shadowOffsetY

    property color shadowColor: Theme.shadowColor

    // Six layers give a smooth transition. With three, rings are visible;
    // above eight there is no visible difference anymore.
    readonly property int warstwy: 6

    Repeater {
        model: root.warstwy

        delegate: Rectangle {
            required property int index

            // Layer 0 is the largest and faintest, the last one -
            // the tightest and darkest. This way darkness
            // builds up towards the shaded element's outline.
            readonly property real oddalenie: 1.0 - (index + 1) / root.warstwy

            // root, not parent: a Repeater creates the delegate without a
            // parent and only then moves it under root (and takes it away
            // again when it is destroyed), so "parent" is null for a moment
            // and every binding on it logged a TypeError. root is always there.
            anchors.horizontalCenter: root.horizontalCenter
            anchors.verticalCenter: root.verticalCenter
            anchors.verticalCenterOffset: root.offsetY * (oddalenie + 0.2)

            width: root.width + 2 * root.spread * oddalenie
            height: root.height + 2 * root.spread * oddalenie
            radius: root.radius + root.spread * oddalenie

            // Alpha divided by the number of layers - only their sum
            // gives the target darkness in the middle of the stack.
            color: Qt.alpha(root.shadowColor,
                            root.shadowColor.a / root.warstwy)
        }
    }
}
