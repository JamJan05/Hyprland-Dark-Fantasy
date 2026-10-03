pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT.
//
// The Quickshell scanner (src/core/scan.cpp) reads the file header line by
// line and stops at the FIRST line containing an opening brace -
// without stripping comments first. A brace in a descriptive comment
// therefore closes the header before the scanner reaches "pragma Singleton",
// and the file registers as a regular type instead of a singleton.
//
// Keeping the pragma on the first line makes the file immune to comment contents.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  NERD FONT GLYPHS.
//
//  THIS FILE IS GENERATED, not rewritten by hand. The code points
//  come, every single one, from config/waybar/config.jsonc (the
//  audio panel script that also used them is gone) - so the same battery,
//  the same speaker and the same power profile look identical on the bar
//  and in the panel, not "almost the same".
//
//  Writing "\u{f057e}" instead of a pasted character is deliberate: glyphs
//  from the Private Use Area tend to get lost by editors,
//  diff tools and copying through the clipboard. A code point survives
//  everything, and the code shows exactly which character is meant.
//
//  Generator script: tools/generuj-ikony-quickshell.py in the repository.
//  Run it from the repo root after adding a new glyph.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import Quickshell

Singleton {
    // ---------------- SOUND ----------------
    // Three fill levels, like the "format-icons" of the pulseaudio
    // module: quiet / medium / loud.
    readonly property list<string> volumeSteps: ["\u{f057f}", "\u{f0580}", "\u{f057e}"]

    // Mute. Waybar uses 0xf075f, and the audio panel 0xf0581 -
    // two different glyphs for the same thing. We take the version from the bar, because it
    // is the one in sight all the time.
    readonly property string volumeMuted: "\u{f075f}"

    readonly property string microphone: "\u{f036c}"
    readonly property string microphoneMuted: "\u{f036d}"
    readonly property string application: "\u{f075a}"
    readonly property string window: "\u{f0614}"
    readonly property string appMenu: "\u{f0570}"
    readonly property string search: "\u{f0349}"
    readonly property string pinned: "\u{f0403}"

    // ---------------- BRIGHTNESS ----------------
    readonly property list<string> brightnessSteps: ["\u{f00de}", "\u{f00df}", "\u{f00e0}"]

    // ---------------- POWER ----------------
    readonly property string profilePerformance: "\u{f04c5}"
    readonly property string profileBalanced: "\u{f0f85}"
    readonly property string profileSaver: "\u{f032a}"

    // ---------------- NETWORK ----------------
    // Four signal strength levels, like the "format-icons" of the network module.
    readonly property list<string> wifiSteps: ["\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"]
    readonly property string wifiOff: "\u{f05aa}"
    readonly property string wifiLocked: "\u{f033e}"

    // ---------------- DESKTOP BEHAVIOUR ----------------
    readonly property string idleOn: "\u{f0176}"
    readonly property string idleOff: "\u{f0faa}"
    readonly property string dndOn: "\u{f009b}"
    readonly property string dndOff: "\u{f009a}"
    readonly property string bellRinging: "\u{f009e}"

    // ---------------- HUD ----------------
    readonly property string cpu: "\u{f0ee0}"
    readonly property string memory: "\u{f035b}"
    readonly property string thermometer: "\u{f050f}"
    readonly property string transfer: "\u{f04e1}"

    // ---------------- MULTIMEDIA ----------------
    readonly property string mediaPrevious: "\u{f04ae}"
    readonly property string mediaNext: "\u{f04ad}"
    readonly property string mediaPlay: "\u{f040a}"
    readonly property string mediaPause: "\u{f03e4}"

    // ---------------- BLUETOOTH ----------------
    readonly property string bluetoothOn: "\u{f00af}"
    readonly property string bluetoothOff: "\u{f00b2}"
    readonly property string bluetoothConnected: "\u{f00b1}"

    // ---------------- BATTERY ----------------
    // Eleven levels, one per 10%. Exactly the same arrays
    // as in the "battery" module - including a separate set for charging
    // and a single "plugged in" glyph.
    readonly property list<string> batterySteps: ["\u{f008e}", "\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}", "\u{f007e}", "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"]
    readonly property list<string> batteryChargingSteps: ["\u{f089f}", "\u{f089c}", "\u{f0086}", "\u{f0087}", "\u{f0088}", "\u{f089d}", "\u{f0089}", "\u{f089e}", "\u{f008a}", "\u{f008b}", "\u{f0085}"]
    readonly property string batteryPlugged: "\u{f06a5}"

    // Picks the battery glyph the way Waybar does: the percentage split
    // into eleven buckets, a separate array while charging, and when
    // on mains power without charging - a single plug glyph.
    function battery(percent, charging, plugged) {
        if (plugged && !charging) return batteryPlugged;
        const tablica = charging ? batteryChargingSteps : batterySteps;
        const i = Math.max(0, Math.min(tablica.length - 1,
                           Math.round(percent * (tablica.length - 1))));
        return tablica[i];
    }

    // Picks a glyph from the step array based on a 0.0-1.0 value.
    // Shared by volume and brightness.
    function step(steps, value) {
        const i = Math.max(0, Math.min(steps.length - 1,
                           Math.floor(value * steps.length)));
        return steps[i];
    }
}
