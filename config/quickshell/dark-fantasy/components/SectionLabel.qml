// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  SECTION HEADER - the caption "Sound", "Display", "Power".
//
//  In Dark Souls style a section label is an inscription, not an alarm - so
//  not bold gold capitals, but EB Garamond in SMALL CAPS, letter-spaced
//  by 1.75 px, in the text color #d7d0c5.
//
//  Gold stays reserved for the "this is active" state (selection, border of
//  the active element) - a gold header would compete with the selection.
//
//  Small caps instead of toUpperCase(): the caller writes normally ("Sound"),
//  a capital letter stays capital, and the rest get the typeface's small caps.
//  All caps would turn everything into equally tall letters and lose
//  the caption's rhythm.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs

Label {
    font.family: Theme.fontDisplay
    // 14 px, not 11 as in mono: Garamond has a low x-height,
    // and small caps are even lower - at 11 px the caption vanished.
    font.pixelSize: Theme.fontSizeNormal + 1
    // The package has only the regular weight; bold would be synthetic.
    font.weight: Font.Normal
    font.capitalization: Font.SmallCaps
    // Lining figures - see Theme.fontDisplay.
    font.features: { "lnum": 1 }
    font.letterSpacing: Theme.sectionLetterSpacing
    color: Theme.text

    text: rawText

    // The caption text. The name is left over from the all-caps days - a dozen
    // or so places read it, so renaming it would gain nothing.
    property string rawText: ""
}
