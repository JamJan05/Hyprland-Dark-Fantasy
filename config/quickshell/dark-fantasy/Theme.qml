pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT.
//
// The Quickshell scanner (src/core/scan.cpp) reads the file header line by
// line and stops at the FIRST line containing "{" - without stripping
// comments first. A brace in a descriptive comment therefore closes the
// header before the scanner reaches "pragma Singleton", and the file gets
// registered as a regular type instead of a singleton. This shows up as
// the error "Property 'x' of object Y is not a function" at the usage site,
// not in this file - which makes the symptom hard to link to the cause.
//
// Keeping the pragma on the first line makes the file immune to comment content.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  THE SINGLE SOURCE OF TRUTH FOR THE LOOK OF THE QUICKSHELL LAYER.
//
//  No other file in this directory may write a color,
//  radius or animation time directly. Everything comes from here.
//
//  The values are NOT made up - they were extracted from what
//  already works in the repository:
//      config/waybar/style.css
//      config/waybar/panel-audio.css
//      config/swaync/style.css
//      config/nwg-dock-hyprland/style.css   (deleted, like the later
//                                            Quickshell dock)
//      config/nwg-drawer/drawer.css   (deleted, like the later
//                                      Quickshell app menu)
//      config/rofi/dark-fantasy.rasi
//      config/kitty/kitty.conf
//      config/hypr/hyprland.lua   (animation curves, blur, shadow)
//
//  Every value has a comment saying where it comes from.
//  If you change a color in those files, change it here too -
//  otherwise the Quickshell panels will visually drift away from the bar.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

// QtQuick is needed for Qt.rgba() and Qt.fontFamilies(). Quickshell
// alone does not bring them - without this import all colors
// with alpha would be "undefined", and the panel would start transparent.
import QtQuick
import Quickshell

Singleton {
    // ================================================================
    //  PALETTE
    //
    //  Eight colors. That many - and not a single one more - is all of
    //  dark-fantasy. Each of them appears in at least four
    //  of the seven existing style files, so this is not one
    //  component's choice, but the language of the whole environment.
    //
    //  The only exception is the three HUD bar colors, confined to a single
    //  use - described next to them, right below iron.
    // ================================================================

    // Panel background. In the CSS files written as rgba(11, 11, 12, α), where
    // alpha depends on what the element sits over - see "panelOpacity".
    readonly property color background: "#0b0b0c"

    // Surface of a card lying ON the panel background. SwayNC paints a single
    // notification with it, rofi - the list, kitty - color0.
    readonly property color surface: "#151311"

    // Raised surface: slider row, tile, hover state.
    // The same shade in waybar (@bg-hover), swaync (@karta-hov),
    // the dock (@bg-hover) and the audio panel (@bg-rzad / @bg-hover) -
    // only the alpha differs.
    readonly property color surfaceAlt: "#201c18"

    // Primary and muted text. They appear in ALL
    // seven style files without exception.
    readonly property color text: "#d7d0c5"
    readonly property color textMuted: "#81786b"

    // Old gold - the only accent in the whole theme. Active desktop,
    // active app in the dock, section headers, cursor in kitty,
    // active Hyprland window border. Nothing else plays this role.
    readonly property color accent: "#b19a67"

    // Ember color - the only alarm. Critical battery, muted sound,
    // "do not disturb", session menu, critical notification.
    // It is NOT "red for everything" - it means "attention".
    readonly property color ember: "#8f4935"

    // Cold iron - disabled and dimmed state. Bluetooth off,
    // notification timestamp, inactive window border.
    readonly property color iron: "#55504a"

    // ----------------------------------------------------------------
    //  HUD BARS - three colors outside the basic eight.
    //
    //  They may be used only in the left-corner stat bars
    //  (hud/HudBars.qml) and in the btop graphs, which mirror them.
    //  They are muted just like the rest of the palette: clotted blood, cold
    //  blue and moss - not the red, blue and green from the game.
    //
    //  Ember (#8f4935) is NOT the HP color, even though it is close. Ember means
    //  "alarm" and appears only on alarm and while charging -
    //  if it painted the HP bar, every glance at the HUD would look like an alarm.
    // ----------------------------------------------------------------
    readonly property color hudHp: "#7a2c26"        // battery
    readonly property color hudFp: "#3f5566"        // RAM
    readonly property color hudStamina: "#4f5d3a"   // CPU

    // ----------------------------------------------------------------
    //  BORDERS
    //
    //  Across the whole repository a border is ALWAYS 1 px and ALWAYS gold
    //  at low alpha. The only 2 px that exist are the gold
    //  "this is active" line (border-bottom in the dock, inset box-shadow on
    //  the active desktop) - hence the separate "borderActiveWidth" value.
    // ----------------------------------------------------------------
    readonly property color border: Qt.rgba(0.694, 0.604, 0.404, 0.20)
    readonly property color borderActive: accent
    readonly property int borderWidth: 1
    readonly property int borderActiveWidth: 2

    // ----------------------------------------------------------------
    //  STATE WASHES
    //
    //  The repository uses gold washes with alpha .14 .16 .18 .20 .24.
    //  That spread is the result of rules added over the years, not of
    //  design - in practice two levels are needed, so two remain.
    // ----------------------------------------------------------------

    // "selected / on": active desktop, bluetooth connected,
    // idle inhibit on, selection in rofi.
    readonly property color accentWash: Qt.rgba(0.694, 0.604, 0.404, 0.16)

    // "strongly selected": active app in the dock, pressed tile.
    readonly property color accentWashStrong: Qt.rgba(0.694, 0.604, 0.404, 0.24)

    // "this will delete / turn off": hover on the session menu, close button,
    // clear-notifications button.
    readonly property color emberWash: Qt.rgba(0.561, 0.286, 0.208, 0.28)

    // Press - a faint flash in the text color. From waybar/style.css,
    // the "#mpris:active" rule and its neighbors.
    readonly property color pressWash: Qt.rgba(0.843, 0.816, 0.773, 0.08)

    // Slider trough - the not-yet-filled part. The audio panel uses .12,
    // the bar .14; we take the panel value, since it is the model for
    // large surfaces.
    readonly property color trough: Qt.rgba(0.843, 0.816, 0.773, 0.12)

    // ================================================================
    //  TRANSPARENCY
    //
    //  In the repository alpha is not random - it is a function of what
    //  the element sits over:
    //      .88      bar and dock, narrow, over the wallpaper
    //      .92-.94  swaync panel, large, over the wallpaper
    //      .96      audio panel, large, over WINDOWS, dense with text
    //      .97-.98  tooltips and menus
    //
    //  Our panels belong to the audio panel category: they are large, full
    //  of text and shown over windows. Hence .96, not .88.
    //  The comment in panel-audio.css says it outright: "at 0.88 as
    //  in Waybar the slider text would get lost on bright parts of the
    //  wallpaper".
    // ================================================================
    readonly property real panelOpacity: 0.96
    readonly property real popupOpacity: 0.98

    // Narrow bar over the wallpaper - the HUD in the left corner, mirroring the Waybar background.
    // The only shell surface in that first category, hence a separate
    // value instead of writing .88 in hud/Hud.qml.
    readonly property real barOpacity: 0.88

    // Muted / unavailable element. From panel-audio.css (.rzad-wyciszony).
    readonly property real disabledOpacity: 0.55

    // ================================================================
    //  GEOMETRY
    //
    //  SHARP RECTANGLES. All three radii are zero.
    //
    //  A Dark Souls-style interface has not a single rounded corner - frames
    //  are forged, not molded - and likewise zero is what Hyprland
    //  (decoration.rounding), Waybar (border-radius), hyprlock (rounding) and
    //  the SDDM theme use.
    //
    //  The property names STAY, even though they all mean the same. A dozen or so
    //  components read them, and a possible return to rounded corners should be
    //  a change of three numbers here, not a search through the whole directory.
    // ================================================================
    readonly property int radiusSmall: 0      // button, tile, slider
    readonly property int radiusMedium: 0     // card inside a panel
    readonly property int radiusLarge: 0      // the panel itself

    // ----------------------------------------------------------------
    //  SPACING
    //
    //  Scale read from the CSS files: 2 3 4 6 8 10 12 14 16.
    //  Reduced to four levels plus a micro spacing for margins
    //  inside rows (waybar uses "margin: 3px 2px" there).
    // ----------------------------------------------------------------
    readonly property int spacingMicro: 3
    readonly property int spacingXs: 4
    readonly property int spacingSm: 6
    readonly property int spacingMd: 10
    readonly property int spacingLg: 16

    // ================================================================
    //  TYPOGRAPHY
    //
    //  The same fallback list as in every CSS file of the repository.
    //
    //  NOTE - QML HAS NO font.families.
    //  In CSS it is enough to write font-family: "a", "b", "c" and the
    //  first existing family wins. QtQuick cannot do that: the "font"
    //  type exposes only a single font.family to QML.
    //  (font.families exists in C++ in QFont, but not in QML -
    //  verified on Qt 6.11.1: the assignment fails with the error
    //  "Cannot assign to non-existent property families".)
    //
    //  So we resolve the fallback list ourselves, ONCE at startup:
    //  we ask Qt for the installed families and take the first one from the list
    //  that actually exists. The effect is the same as in CSS, and as a
    //  bonus it is impossible to request a font that is not there by mistake.
    // ================================================================
    readonly property list<string> fontFallback: [
        "JetBrainsMono Nerd Font",
        "Hack Nerd Font",
        "Symbols Nerd Font",
        "Noto Sans"
    ]

    // The result is computed once - Qt.fontFamilies() on this machine
    // returns 1860 entries, so there is no point searching that list
    // for every piece of text in a panel.
    readonly property string fontFamily: {
        const zainstalowane = Qt.fontFamilies();
        for (const rodzina of fontFallback) {
            if (zainstalowane.indexOf(rodzina) !== -1) return rodzina;
        }
        // None from the list is installed - an empty string tells
        // Qt to use the system default font instead of drawing boxes.
        return "";
    }

    // Typeface for numbers and values: clock, percentages, temperature. The same
    // family as fontFamily - the separate name tells the caller "this is a
    // value", and fixed-width digits do not dance when they change.
    readonly property string fontMono: fontFamily

    // ----------------------------------------------------------------
    //  DISPLAY TYPEFACE - EB Garamond in small caps
    //
    //  Headers, section labels, tile captions, date and weekday.
    //
    //  The media-fonts/eb-garamond package (version 0.016 by Georg Duffner)
    //  registers the "EB Garamond" family, and next to it the optical variants
    //  "EB Garamond 12" and "EB Garamond 08". Cormorant Garamond is a fallback
    //  from outside Portage, installed manually into ~/.local/share/fonts.
    //
    //  Small caps are enabled by the caller: font.capitalization: Font.SmallCaps,
    //  together with font.features: { "lnum": 1 }. Without "lnum" Garamond draws
    //  old-style figures and "11" in small caps reads like Roman "II".
    //
    //  In QML - the "EB Garamond" family + SmallCaps. In Waybar and hyprlock
    //  (Pango) - the separate "EB Garamond SC" family. Reason for the difference: Pango
    //  with small-caps enables the typeface's "smcp" feature, which in version 0.016 does not
    //  have the letter "ł", so "Popiół" comes out as "Popió ". Qt composes small caps
    //  differently and draws "ł" correctly; the SC family in Qt, on the other hand, gets
    //  artificially emboldened letters. Verified by rendering both variants
    //  in qml6 and pango-view.
    // ----------------------------------------------------------------
    readonly property list<string> fontDisplayFallback: [
        "EB Garamond",
        "EB Garamond 12",
        "Cormorant Garamond"
    ]

    readonly property string fontDisplay: {
        const zainstalowane = Qt.fontFamilies();
        for (const rodzina of fontDisplayFallback) {
            if (zainstalowane.indexOf(rodzina) !== -1) return rodzina;
        }
        // Without Garamond, headers fall back to the mono typeface, not the system
        // default sans-serif - at least they stay consistent with the rest.
        return fontFamily;
    }

    // Small caps letter spacing. The prompt allows 1.5-2 px; 1.75 reads
    // like an inscription at 13-15 px, and at larger sizes does not scatter
    // the text into individual letters.
    readonly property real displayLetterSpacing: 1.75

    // 11 - timestamp, caption, SECTION HEADER
    // 13 - base; this size is set by the "*" rule in all five CSS files
    // 15 - panel title, swaync widget header
    // 16 - icon as a button
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeIcon: 16

    readonly property int fontWeightNormal: 500
    readonly property int fontWeightMedium: 600
    readonly property int fontWeightBold: 700

    // The section header is in EB Garamond small caps, so its letter spacing
    // follows the display typeface.
    readonly property real sectionLetterSpacing: displayLetterSpacing

    // ================================================================
    //  MOTION
    //
    //  Only a slow crossfade. No springs, no growing
    //  ("popin") and no bounce at the end - a menu in this style does not pop up,
    //  it emerges from the darkness.
    //
    //  Small element timings were kept from the repository's CSS:
    //      150 ms - slider handle, list item
    //      200 ms - bar module, tile, state change
    //
    //  Panel timings are shared with config/hypr/hyprland.lua, leaf "layers".
    //  A Quickshell panel is a layer-shell surface, i.e. EXACTLY
    //  what that leaf animates:
    //
    //      layersIn   speed 5   easeOutQuint  fade   -> 500 ms
    //      layersOut  speed 2   linear        fade   -> 200 ms
    //
    //  (speed is in deciseconds, 1 = 100 ms - see the comment
    //  at hl.animation in hyprland.lua.)
    //
    //  Entry stays ~2.5x slower than exit: emerging should be
    //  slow, and closing must not keep you waiting.
    //
    //  No scale for panels: Hyprland windows only crossfade too ("popin 100%").
    // ================================================================
    readonly property int animFast: 150
    readonly property int animNormal: 200
    readonly property int animPanelIn: 500
    readonly property int animPanelOut: 200

    // hl.curve("easeOutQuint", { points = { {0.23, 1}, {0.32, 1} } })
    // QML expects the full list of control points ending with (1,1).
    // No point goes above 1.0, so the curve does not bounce.
    readonly property list<real> easeOutQuint: [0.23, 1.0, 0.32, 1.0, 1.0, 1.0]

    // hl.curve("quick", { points = { {0.15, 0}, {0.1, 1} } })
    readonly property list<real> easeQuick: [0.15, 0.0, 0.10, 1.0, 1.0, 1.0]

    // How many pixels the notification tooltip and the OSD drift up by when
    // appearing. The only motion besides crossfade that the theme
    // allows: too small to read as an animation, but enough
    // for the eye to catch where something came from.
    readonly property int driftDistance: 8

    // ================================================================
    //  GRAIN - "ash, not smooth black"
    //
    //  Opacity of the noise texture (assets/szum.png from tools/generuj-szum.py)
    //  laid under every shell surface - see
    //  components/Szum.qml. The prompt allows 6-8 %.
    // ================================================================
    readonly property real noiseOpacity: 0.07

    // ================================================================
    //  SHADOW
    //
    //  All shadows in the repository are cast in near-black #060607 -
    //  the same one Hyprland shades windows with (color = 0xcc060607).
    //  QtQuick has no box-shadow; MultiEffect draws it - see
    //  components/PanelSurface.qml.
    //
    //      swaync .control-center:  0 8px 24px rgba(6,6,7,.65)
    // ================================================================
    readonly property color shadowColor: Qt.rgba(0.024, 0.024, 0.027, 0.65)
    readonly property int shadowBlur: 24
    readonly property int shadowOffsetY: 8

    // ================================================================
    //  TOP BAR - dimensions shared with Waybar
    //
    //  Mirror of "height", "margin-top" and "margin-left" from
    //  config/waybar/config.jsonc. Waybar does not read QML, so these numbers
    //  exist in two places - there they carry the comment
    //  "MIRRORS Theme.qml", just like the palette in style.css.
    //
    //  They are read by the HUD panel in the left corner: it must have IDENTICAL height,
    //  margin and outline to the bar pills, so that it reads as part
    //  of them, not as a separate widget placed next to them.
    // ================================================================
    readonly property int barHeight: 38
    readonly property int barMarginTop: 6
    readonly property int barMarginSide: 12

    // ================================================================
    //  PANEL PLACEMENT
    //
    //  Panels open right under the bar, so everything opens in the same place.
    //
    //  44 px is the bottom edge of the bar pill:
    //      6 px  bar margin-top    (config.jsonc)
    //    + 38 px bar height        (config.jsonc)
    //    = 44
    //
    //  The pills have no vertical margin (style.css) and take the full 38 px:
    //  the left corner with the HUD (three stat bars and a row of desktops)
    //  does not fit in less. A margin there would make the pill shorter than
    //  the bar layer, and a panel at 44 px would leave a strip of wallpaper.
    //  The bar, HUD and panels are computed from one pair of numbers.
    //
    //  Deliberately WITHOUT a gap. SwayNC and the audio panel add another
    //  6 px of slack (hence their 50) and so look like separate windows
    //  that happen to hang under the bar. A Quickshell panel is meant to
    //  look slid out FROM the bar, so it touches it edge to edge,
    //  and its top corners are cut - see "attachedTop"
    //  in components/PanelSurface.qml.
    //
    //  This value is also the input mask boundary: the area above it
    //  belongs to Waybar and the panel does not capture it, so that a click
    //  on the cogwheel reaches the bar.
    // ================================================================
    readonly property int panelMarginTop: barMarginTop + barHeight
    readonly property int panelMarginRight: 12

    // Panel width. SwayNC has 440, the audio panel 420. We take 420 -
    // at 440 the slider card gets needlessly spread out.
    readonly property int panelWidth: 420

    // ================================================================
    //  HUD - left corner of the bar (hud/Hud.qml)
    //
    //  An emblem with the floor's Roman numeral, next to it three stat bars, below them
    //  the row of desktops and stacking statuses. The game's HUD layout, but on
    //  computer data: HP is the battery, FP memory, stamina the CPU.
    // ================================================================

    // HUD window width. Fixed, not computed from the bar lengths:
    // Waybar shifts the window title by exactly this much (margin-left of #window
    // in style.css mirrors this value), and CSS does not know how long
    // the bars came out on a given machine.
    readonly property int hudWidth: 420

    // Bar height and gap - faithful to the game. Readability comes from LENGTH.
    readonly property int hudBarHeight: 6
    readonly property int hudBarGap: 2

    // Bar length follows from the hardware "stats", like a character's max HP:
    //   HP       4 px per Wh of battery design capacity     (64 Wh    -> 256 px)
    //   FP      14 px per GiB of RAM                        (13.3 GiB -> 186 px)
    //   stamina 12 px per CPU thread                        (16 threads -> 192 px)
    readonly property int hudPxPerWh: 4
    readonly property int hudPxPerGiB: 14
    readonly property int hudPxPerThread: 12

    // Upper limit of bar length. A workstation with 64 GiB RAM would give FP at
    // almost 900 px, and the bar cannot extend past the corner - at large
    // values it stops. 420 - emblem 34 - gap 8 - margin 8.
    readonly property int hudBarMax: hudWidth - 50

    // A computer without a battery (desktop) gets a full HP bar of this
    // length - "mains power" - instead of a hole in the HUD silhouette.
    readonly property int hudHpBezBaterii: 256

    // HUD bars on by default. The current state (Cogwheel, "qs ipc call
    // hud przelaczPaski") is held by services/UstawieniaPowloki.qml, because it has to
    // survive a shell restart - here is the value a fresh
    // install starts from.
    readonly property bool hudBars: true

    // Digit in the desktop square (mono 8 px). Off by default -
    // the square's position tells which desktop it is anyway.
    readonly property bool workspaceNumbers: false

    // ================================================================
    //  TILE ROW - menu at the bottom of the screen (kafle/RzadKafli.qml)
    // ================================================================

    // 76 px, not 64: the relief on the icons (bronze bas-relief) at
    // 64 px blurs into a blob - the swords and the satchel stop being recognizable.
    readonly property int kafelRozmiar: 76
    readonly property int kafelOdstep: 10

    // Pause dims the desktop to 40 % brightness: a black layer at 60 %
    // opacity. No blur - the world under the menu should stay sharp, just dark.
    readonly property real pauzaPrzyciemnienie: 0.6
}
