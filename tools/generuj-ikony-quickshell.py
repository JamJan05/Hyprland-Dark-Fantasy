# Generates Icons.qml from EXACTLY the same code points
# that config/waybar/config.jsonc uses.
def q(cp): return '"\\u{%x}"' % cp
def arr(cps): return "[" + ", ".join(q(c) for c in cps) + "]"

GLOSNOSC   = [0xF057F, 0xF0580, 0xF057E]
GLOSNOSC_X = 0xF075F
MIKROFON   = 0xF036C
MIKROFON_X = 0xF036D
JASNOSC    = [0xF00DE, 0xF00DF, 0xF00E0]
PROFIL     = {"performance": 0xF04C5, "balanced": 0xF0F85, "power-saver": 0xF032A}
BAT        = [0xF008E,0xF007A,0xF007B,0xF007C,0xF007D,0xF007E,0xF007F,0xF0080,0xF0081,0xF0082,0xF0079]
BAT_LAD    = [0xF089F,0xF089C,0xF0086,0xF0087,0xF0088,0xF089D,0xF0089,0xF089E,0xF008A,0xF008B,0xF0085]
BAT_SIEC   = 0xF06A5
# NOTE: despite the name this is a MUSIC NOTE (nf-md-music), not an app icon -
# verified by rendering the glyph. It stays, because both places that
# use it are musical: the fallback album cover and the audio stream
# of a specific program. The dock tile uses OKNO below.
APLIKACJA  = 0xF075A
# Fallback dock tile, when the icon theme does not know the app.
# nf-md-application - a window frame. F0614, not F075A.
OKNO       = 0xF0614
# App menu button in the dock. The only glyph in this file that does NOT
# come from config.jsonc - the bar has no launcher module, because the menu
# opens with the SUPER+R shortcut. nwg-dock drew an icon from the GTK theme here;
# in the shell we take a grid from the Nerd Font, so the button looks the
# same regardless of the installed icon theme.
MENU       = 0xF0570   # 󰕰 view-grid
# The app menu is now drawn by the shell itself, so two glyphs were added that
# the bar does not have: a magnifier in the search field and a pin on the tile of a pinned
# app. Checked after rendering, like all the rest.
SZUKAJ     = 0xF0349   # 󰍉 magnify
PINEZKA    = 0xF0403   # 󰐃 pin
# Bluetooth - the same glyphs the "bluetooth" module on the bar uses
BT_ON      = 0xF00AF   # 󰂯 on, no connections
BT_OFF     = 0xF00B2   # 󰂲 off
BT_CONN    = 0xF00B1   # 󰂱 connected
# Media. Previous and next are the same ones the "custom/media-*"
# buttons on the bar use; play and pause are added separately, because the bar
# only has a shared "play-pause" glyph and does not distinguish the state.
MEDIA_PREV  = 0xF04AE  # 󰒮
MEDIA_NEXT  = 0xF04AD  # 󰒭
MEDIA_PLAY  = 0xF040A  # 󰐊
MEDIA_PAUSE = 0xF03E4  # 󰏤
# Network - the same glyphs the "network" module on the bar uses
WIFI       = [0xF091F, 0xF0922, 0xF0925, 0xF0928]
WIFI_OFF   = 0xF05AA   # 󰖪
# Padlock next to a secured network. U+F0BBB (wifi-lock) looks good
# in the glyph table, but is a FULL-width character and at 13-15 px
# renders as an unreadable crumb - verified on a screenshot.
# nf-md-lock has normal icon width and reads at every size.
WIFI_LOCK  = 0xF033E   # 󰌾 padlock
# Desktop behavior - the same glyphs the "idle_inhibitor" module
# on the bar used, plus the bells from SwayNC.
IDLE_ON    = 0xF0176   # 󰅶 idle blanking inhibited
IDLE_OFF   = 0xF0FAA   # 󰾪 idle blanking works normally
# Bells. Chosen after RENDERING the whole F009A-F00A0 family
# and looking at it - F09A2, which in the table looked like a crossed-out
# bell, turned out to be a speaker with Bluetooth.
DND_ON     = 0xF009B   # 󰂛 crossed-out bell
DND_OFF    = 0xF009A   # 󰂚 bell
BELL_RING  = 0xF009E   # 󰂞 ringing bell - there are notifications
# Left-corner HUD and the numbers on the bar when the HUD bars are off.
# CPU and memory - the same glyphs the "cpu" and "memory" modules
# in config.jsonc used; thermometer - the one from local/bin/waybar-temperatura.
CPU        = 0xF0EE0   # 󰻠 CPU
RAM        = 0xF035B   # 󰍛 memory stick
TERMOMETR  = 0xF050F   # 󰔏 thermometer
# Transfer status: two up-down arrows (nf-md-swap-vertical) - traffic
# in both directions, without distinguishing download from upload.
TRANSFER   = 0xF04E1   # 󰓡 up-down arrows

TXT = f'''pragma Singleton

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
//  Writing "\\u{{f057e}}" instead of a pasted character is deliberate: glyphs
//  from the Private Use Area tend to get lost by editors,
//  diff tools and copying through the clipboard. A code point survives
//  everything, and the code shows exactly which character is meant.
//
//  Generator script: tools/generuj-ikony-quickshell.py in the repository.
//  Run it from the repo root after adding a new glyph.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import Quickshell

Singleton {{
    // ---------------- SOUND ----------------
    // Three fill levels, like the "format-icons" of the pulseaudio
    // module: quiet / medium / loud.
    readonly property list<string> volumeSteps: {arr(GLOSNOSC)}

    // Mute. Waybar uses 0xf075f, and the audio panel 0xf0581 -
    // two different glyphs for the same thing. We take the version from the bar, because it
    // is the one in sight all the time.
    readonly property string volumeMuted: {q(GLOSNOSC_X)}

    readonly property string microphone: {q(MIKROFON)}
    readonly property string microphoneMuted: {q(MIKROFON_X)}
    readonly property string application: {q(APLIKACJA)}
    readonly property string window: {q(OKNO)}
    readonly property string appMenu: {q(MENU)}
    readonly property string search: {q(SZUKAJ)}
    readonly property string pinned: {q(PINEZKA)}

    // ---------------- BRIGHTNESS ----------------
    readonly property list<string> brightnessSteps: {arr(JASNOSC)}

    // ---------------- POWER ----------------
    readonly property string profilePerformance: {q(PROFIL["performance"])}
    readonly property string profileBalanced: {q(PROFIL["balanced"])}
    readonly property string profileSaver: {q(PROFIL["power-saver"])}

    // ---------------- NETWORK ----------------
    // Four signal strength levels, like the "format-icons" of the network module.
    readonly property list<string> wifiSteps: {arr(WIFI)}
    readonly property string wifiOff: {q(WIFI_OFF)}
    readonly property string wifiLocked: {q(WIFI_LOCK)}

    // ---------------- DESKTOP BEHAVIOUR ----------------
    readonly property string idleOn: {q(IDLE_ON)}
    readonly property string idleOff: {q(IDLE_OFF)}
    readonly property string dndOn: {q(DND_ON)}
    readonly property string dndOff: {q(DND_OFF)}
    readonly property string bellRinging: {q(BELL_RING)}

    // ---------------- HUD ----------------
    readonly property string cpu: {q(CPU)}
    readonly property string memory: {q(RAM)}
    readonly property string thermometer: {q(TERMOMETR)}
    readonly property string transfer: {q(TRANSFER)}

    // ---------------- MULTIMEDIA ----------------
    readonly property string mediaPrevious: {q(MEDIA_PREV)}
    readonly property string mediaNext: {q(MEDIA_NEXT)}
    readonly property string mediaPlay: {q(MEDIA_PLAY)}
    readonly property string mediaPause: {q(MEDIA_PAUSE)}

    // ---------------- BLUETOOTH ----------------
    readonly property string bluetoothOn: {q(BT_ON)}
    readonly property string bluetoothOff: {q(BT_OFF)}
    readonly property string bluetoothConnected: {q(BT_CONN)}

    // ---------------- BATTERY ----------------
    // Eleven levels, one per 10%. Exactly the same arrays
    // as in the "battery" module - including a separate set for charging
    // and a single "plugged in" glyph.
    readonly property list<string> batterySteps: {arr(BAT)}
    readonly property list<string> batteryChargingSteps: {arr(BAT_LAD)}
    readonly property string batteryPlugged: {q(BAT_SIEC)}

    // Picks the battery glyph the way Waybar does: the percentage split
    // into eleven buckets, a separate array while charging, and when
    // on mains power without charging - a single plug glyph.
    function battery(percent, charging, plugged) {{
        if (plugged && !charging) return batteryPlugged;
        const tablica = charging ? batteryChargingSteps : batterySteps;
        const i = Math.max(0, Math.min(tablica.length - 1,
                           Math.round(percent * (tablica.length - 1))));
        return tablica[i];
    }}

    // Picks a glyph from the step array based on a 0.0-1.0 value.
    // Shared by volume and brightness.
    function step(steps, value) {{
        const i = Math.max(0, Math.min(steps.length - 1,
                           Math.floor(value * steps.length)));
        return steps[i];
    }}
}}
'''
open('config/quickshell/dark-fantasy/Icons.qml','w',encoding='utf-8').write(TXT)
print("saved")
