// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  PANEL TITLE - "System", "Notifications", "Media".
//
//  EB Garamond in small caps, letter-spaced, in the text color. The same
//  set as the section label (SectionLabel.qml), only larger - a panel
//  and a section differ in size, not in typeface or color.
//
//  Not bold: the packaged Garamond has only the regular weight, so bold
//  would be synthetic (smeared) - size and letter-spacing stand in for
//  weight here.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs

Label {
    font.family: Theme.fontDisplay
    font.pixelSize: Theme.fontSizeLarge + 5
    font.weight: Font.Normal
    font.capitalization: Font.SmallCaps
    // Lining figures - see Theme.fontDisplay.
    font.features: { "lnum": 1 }
    font.letterSpacing: Theme.displayLetterSpacing + 0.25
    color: Theme.text
}
