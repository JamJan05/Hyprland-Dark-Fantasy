pragma ComponentBehavior: Bound

// Pragma on the first line, before the comment - reason in Icons.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  TILE ROW - the menu at the bottom of the screen, modelled on the Dark Souls main menu.
//
//      [Arsenal] [Satchel] [Status] [Tidings] [Cogwheel] [Bonfire]
//
//  Replaced the dock and the app menu window. One element instead of two:
//  six tiles, and the content of each opens ABOVE the row.
//
//  ---------------------------------------------------------------
//  TWO STATES
//
//  REST - row visible, desktop not dimmed, no background or lines.
//  A tile is selected by hovering the mouse. On an EMPTY desktop the row
//  also holds the keyboard (there is no window to take it from): ← → walk
//  the row, ↓ / Enter use the tile, typing at the Arsenal opens its search.
//
//  PAUSE (SUPER+R or a click on the strip at the bottom edge of the screen)
//  - desktop dimmed to 40 % (no blur: the world
//  under the menu stays sharp), a thin gold line above and below the row,
//  the content of the selected tile opens above the row. The pause takes
//  the keyboard:
//
//      ← →          change tile, with wrapping (nawigacja.js)
//      ↓ / Enter    use the tile (enter its content)
//      Esc          back one level; on the row - exit the pause
//
//  LEVELS. Level 0 is the tile row, level 1 - the tile content (e.g. the
//  program grid in the Arsenal). On level 1 keys go to the content,
//  and whatever it does not handle (Esc on an empty search) goes back to the row.
//  Starting to type on the row at a tile with content moves straight
//  into it - SUPER+R and typing a program name works like in the old menu.
//
//  MOUSE: ONE CLICK USES THE TILE.
//
//  The first version worked like a menu tab in the game: the first click
//  opened the pause with the tile description, only the second one used it. In the game this
//  makes sense, because the tab's content is visible above it right away. Here most tiles
//  open a window or launch a program, so the result was dimming the
//  screen before every launch - Janek found it odd and was
//  right. Now a click uses the tile right away: a tile with an action performs it,
//  a tile with its own content (Arsenal, Tidings, Cogwheel, Bonfire)
//  opens it in the pause above the row.
//
//  The pause state is held by shell.qml, like the state of every panel - the row asks
//  for a change with a signal. What using a tile does is also decided by shell.qml:
//  it opens existing panels and launches programs.
//
//  ---------------------------------------------------------------
//  HIDING - CARRIED OVER 1:1 FROM THE OLD DOCK
//
//  The same rule and the same implementation as in the dock the row replaced
//  (and before that in config/hypr/dock.lua with nwg-dock):
//      empty desktop                 -> row visible
//      a window appears              -> row hides
//      last window closed            -> comes back
//      cursor at the bottom edge     -> row shows
//      cursor on the row             -> stays
//      cursor moved away             -> hides again after 0.45 s
//  Cursor detection is an input mask (a 3 px strip at the edge plus the row
//  outline) and a HoverHandler - no polling and no background timers. dock.lua
//  had to poll the cursor position every 120 ms, because the hidden GTK dock did not
//  know the mouse was over it. Here the layer window never disappears -
//  only its mask changes, so moving into the strip at the edge is
//  an ordinary hover event.
//
//  The strip is narrow on purpose: everything that passes through it is
//  taken away from the window underneath, and within 3 px of the screen edge you
//  cannot meaningfully aim anyway. The pitfalls (Hyprland's lazy models, Region.item)
//  are described next to the code below.
//
//  Hiding is the same crossfade - the dock also slid down, but the theme
//  no longer allows any motion other than crossfading.
//
//  THE WELCOME LAYOUT (local/bin/uklad-startowy) opens three windows after login,
//  so the row starts hidden - an intended consequence of the rule
//  "windows on the desktop = row hidden", not a bug.
//
//  ---------------------------------------------------------------
//  ONE FULLSCREEN WINDOW
//
//  The dimming, lines, row and content live in one layer window
//  covering the whole screen. At rest its mask covers only the strip at the edge
//  and the row, so the mouse passes straight through the rest of the screen; in pause - the whole
//  screen, so that a click on the dimming closes the pause.
//
//  The layer rule in hyprland.lua (order = -2) puts this window above the HUD
//  and Waybar - the pause dimming covers the bar too, like in the game.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.components
import qs.services
import "nawigacja.js" as Nawigacja

PanelWindow {
    id: root

    // ---- INPUT - set by shell.qml ----
    property bool pauza: false

    // Another panel (media, quick panel) is open and needs the keyboard itself.
    property bool innyPanel: false

    // ---- OUTPUT ----
    signal pauzaProszona()
    signal zamkniecieProszone()
    signal uzyto(string klucz)

    WlrLayershell.namespace: "quickshell-kafle"
    WlrLayershell.layer: WlrLayer.Top

    // Keyboard in pause, and at rest on an empty desktop - there are no
    // windows to steal typing from, so the arrows can walk the row right away.
    // As soon as a window appears (or another panel opens) the row lets go.
    WlrLayershell.keyboardFocus: root.klawiatura
        ? WlrKeyboardFocus.Exclusive
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

    // ---------------------------------------------------------------
    //  TILES
    //
    //  Order = order in the row. "klucz" is also the icon file name
    //  (tools/skaluj-ikony-menu.py has the same list). "akcja" says what
    //  Enter will do; empty = tile without content yet.
    // ---------------------------------------------------------------
    readonly property var kafle: [
        { klucz: "uzbrojenie", nazwa: Tr.t("Arsenal", "Uzbrojenie"),
          naglowek: Tr.t("Arsenal", "Uzbrojenie"),
          opis: Tr.t("Every program installed on the system.",
                     "Wszystkie programy zainstalowane w systemie."),
          akcja: "", zawartosc: true },
        { klucz: "sakwa", nazwa: Tr.t("Satchel", "Sakwa"),
          naglowek: Tr.t("Satchel", "Sakwa"),
          opis: Tr.t("Files: the yazi manager in its own terminal window.",
                     "Pliki: menedżer yazi w osobnym oknie terminala."),
          akcja: Tr.t("open file manager", "otwórz menedżer plików") },
        { klucz: "status", nazwa: Tr.t("Status", "Status"),
          naglowek: Tr.t("Status", "Status"),
          opis: Tr.t("Computer state in btop: CPU, memory, disks, network and processes.",
                     "Stan komputera w btop: procesor, pamięć, dyski, sieć i procesy."),
          akcja: Tr.t("open system monitor", "otwórz monitor systemu") },
        { klucz: "wiesci", nazwa: Tr.t("Tidings", "Wieści"),
          naglowek: Tr.t("Tidings", "Wieści"),
          opis: Tr.t("Notification history and “do not disturb” mode.",
                     "Historia powiadomień i tryb „nie przeszkadzać”."),
          akcja: "", zawartosc: true },
        { klucz: "zebatka", nazwa: Tr.t("Cogwheel", "Zębatka"),
          naglowek: Tr.t("Cogwheel", "Zębatka"),
          opis: Tr.t("Sound, display, power, network and Hyprland settings.",
                     "Dźwięk, ekran, zasilanie, sieć i ustawienia Hyprlanda."),
          akcja: "", zawartosc: true },
        { klucz: "ognisko", nazwa: Tr.t("Bonfire", "Ognisko"),
          naglowek: Tr.t("Rest by the fire", "Odpocznij przy ognisku"),
          opis: Tr.t("Lock, suspend, log out, restart and shut down.",
                     "Blokada, uśpienie, wylogowanie, restart i wyłączenie."),
          akcja: "", zawartosc: true }
    ]

    property int wybrany: 0

    readonly property var kafel: kafle[wybrany]

    // 0 = tile row, 1 = tile content - see "LEVELS" in the header.
    property int poziom: 0

    // Changing the tile always returns to the row.
    onWybranyChanged: poziom = 0

    function maZawartosc(k: var): bool {
        return k.zawartosc === true;
    }

    // Content element of the selected tile - keys on level 1 go
    // to it. null = tile without content.
    function zawartosc(): var {
        switch (kafel.klucz) {
        case "uzbrojenie": return uzbrojenie;
        case "wiesci":     return wiesci;
        case "zebatka":    return zebatka;
        case "ognisko":    return ognisko;
        }
        return null;
    }

    function wybierz(klucz: string): void {
        for (let i = 0; i < kafle.length; i++) {
            if (kafle[i].klucz === klucz) wybrany = i;
        }
    }

    // Selects a tile and immediately enters its content, if it has any.
    // This is how SUPER+R opens the pause: the keyboard cursor straight in the program grid.
    function wejdz(klucz: string): void {
        wybierz(klucz);
        if (maZawartosc(kafel)) poziom = 1;
    }

    // Tile with content - open it above the row (pause, level 1).
    // Tile with an action - use it. A tile with neither shows its
    // description in the pause (none like that is left today, but the rule stays for
    // future tiles).
    function uzyjWybranego(): void {
        if (maZawartosc(kafel)) {
            poziom = 1;
            if (!pauza) pauzaProszona();
        } else if (kafel.akcja !== "") {
            uzyto(kafel.klucz);
        } else if (!pauza) {
            pauzaProszona();
        }
    }

    // ---------------------------------------------------------------
    //  WHAT IS ON THE DESKTOP - 1:1 from the old dock.
    // ---------------------------------------------------------------
    readonly property var pulpit: Hyprland.focusedWorkspace

    // Windows of the current desktop. That is the whole "filtering" - Quickshell keeps
    // a separate window model for each desktop. Layer-shell surfaces
    // (bar, HUD, popups, wallpaper) are not XDG windows, so Hyprland does not
    // place them on desktops at all - there is nothing to filter out by class.
    //
    // BEWARE OF SHELL STARTUP: Hyprland models in Quickshell are populated
    // LAZILY, only once something binds to them, and asynchronously.
    // For the first moment after startup the list may be empty, and focusedWorkspace
    // is null - the row then shows as if on an empty desktop and hides
    // only once the data arrives. We do NOT call refreshWorkspaces() here "just
    // to be safe": called too early, before the IPC socket is up, it leaves
    // desktops without identifiers (id = -1) in the model and focusedWorkspace
    // empty forever. Verified with the dock - the binding alone is enough.
    readonly property var okna: pulpit ? pulpit.toplevels.values : []

    // The scratchpad counts as "desktop occupied", but only when it is
    // revealed. Quickshell does not expose it as a separate property, so
    // we take it from the monitor's raw JSON - the "specialWorkspace" field has
    // a non-zero id when the scratchpad is on top. The reading refreshes
    // on monitor events, so it can be a fraction of a second late;
    // the effect is the row staying visible a moment longer, nothing serious.
    readonly property bool scratchpadNaWierzchu: {
        const m = Hyprland.focusedMonitor;
        if (!m || !m.lastIpcObject) return false;
        const s = m.lastIpcObject.specialWorkspace;
        return !!s && s.id !== 0;
    }

    readonly property bool pustyPulpit: okna.length === 0 && !scratchpadNaWierzchu

    // Cursor in the row zone (the strip at the edge or the row itself).
    property bool odsloniety: false

    readonly property bool pokazany: pustyPulpit || odsloniety || pauza

    // Row holds the keyboard - see WlrLayershell.keyboardFocus above.
    readonly property bool klawiatura: pauza || (pustyPulpit && !innyPanel)

    // Delay before hiding. Without it, sliding two pixels off a tile -
    // or moving the mouse diagonally - would hide the row exactly when
    // you are aiming at something. 450 ms is the value from the old dock.lua (4 ticks
    // of 120 ms), carried through the dock unchanged.
    Timer {
        id: chowanie
        interval: 450
        onTriggered: root.odsloniety = false
    }

    // ---------------------------------------------------------------
    //  DIMENSIONS
    // ---------------------------------------------------------------
    readonly property int pasekWywolawczy: 3
    readonly property int marginesDolny: 18

    // Name of the selected tile above the row: 18 px of typeface plus spacing.
    readonly property int wysokoscNazwy: 34

    readonly property int szerokoscRzedu:
        kafle.length * Theme.kafelRozmiar + (kafle.length - 1) * Theme.kafelOdstep

    readonly property int rzadX: Math.round((width - szerokoscRzedu) / 2)
    readonly property int rzadY: height - marginesDolny - Theme.kafelRozmiar

    // ---------------------------------------------------------------
    //  INPUT MASK - see "ONE FULLSCREEN WINDOW" in the header.
    //
    //  Numbers, not Region.item. Region has an "item" property, which
    //  was the obvious choice - and in the dock it did not work: it lost the cursor
    //  the moment it moved from the trigger strip onto the icons, because the outline
    //  never made it into the mask at all. The same region given as a rectangle works.
    // ---------------------------------------------------------------
    mask: Region {
        x: 0
        y: root.pauza ? 0 : root.height - root.pasekWywolawczy
        width: root.width
        height: root.pauza ? root.height : root.pasekWywolawczy

        Region {
            intersection: Intersection.Combine

            readonly property int zapas: 12

            x: root.rzadX - zapas
            y: root.rzadY - root.wysokoscNazwy - zapas
            width: root.pokazany ? root.szerokoscRzedu + 2 * zapas : 0
            height: root.pokazany
                ? root.height - (root.rzadY - root.wysokoscNazwy - zapas)
                : 0
        }
    }

    // ---------------------------------------------------------------
    //  KEYBOARD - one focus owner (pitfall 15 in the notes:
    //  a second element with "focus" stole focus on opening).
    // ---------------------------------------------------------------
    onPauzaChanged: if (!pauza) poziom = 0;

    onKlawiaturaChanged: {
        if (klawiatura) Qt.callLater(() => odbiornik.forceActiveFocus());
    }

    Item {
        id: odbiornik
        focus: true

        Keys.onPressed: function (zdarzenie) {
            if (!root.klawiatura) return;

            // At rest on an empty desktop: arrows walk the row, Enter / Down
            // uses the tile (content tiles open the pause), typing at the
            // Arsenal opens the pause straight into the search. Esc has nothing to close.
            if (!root.pauza) {
                switch (zdarzenie.key) {
                case Qt.Key_Left:
                    root.wybrany = Nawigacja.zawin(root.wybrany, -1, root.kafle.length);
                    break;
                case Qt.Key_Right:
                    root.wybrany = Nawigacja.zawin(root.wybrany, 1, root.kafle.length);
                    break;
                case Qt.Key_Down:
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    root.uzyjWybranego();
                    break;
                default:
                    // Only typing opens the Arsenal - Esc, Tab and the rest
                    // must not open the pause.
                    if (root.kafel.klucz !== "uzbrojenie" || !uzbrojenie.jestTekstem(zdarzenie))
                        return;
                    // Pause first: opening the Arsenal clears its search,
                    // so the typed letter has to come after.
                    root.pauzaProszona();
                    root.poziom = 1;
                    uzbrojenie.klawisz(zdarzenie);
                }
                zdarzenie.accepted = true;
                return;
            }

            // Content level: the content first, and an Esc it did not
            // handle goes back to the row.
            if (root.poziom === 1) {
                const z = root.zawartosc();
                if (z !== null && z.klawisz(zdarzenie)) {
                    zdarzenie.accepted = true;
                    return;
                }
                if (zdarzenie.key === Qt.Key_Escape) {
                    root.poziom = 0;
                    zdarzenie.accepted = true;
                }
                return;
            }

            switch (zdarzenie.key) {
            case Qt.Key_Left:
                root.wybrany = Nawigacja.zawin(root.wybrany, -1, root.kafle.length);
                break;
            case Qt.Key_Right:
                root.wybrany = Nawigacja.zawin(root.wybrany, 1, root.kafle.length);
                break;
            case Qt.Key_Down:
            case Qt.Key_Return:
            case Qt.Key_Enter:
                root.uzyjWybranego();
                break;
            case Qt.Key_Escape:
                root.zamkniecieProszone();
                break;
            default:
                // Typing on the row at the Arsenal - straight into the search.
                if (root.kafel.klucz === "uzbrojenie") {
                    root.poziom = 1;
                    if (uzbrojenie.klawisz(zdarzenie)) break;
                }
                return;
            }
            zdarzenie.accepted = true;
        }
    }

    // ---------------------------------------------------------------
    //  SCENE
    // ---------------------------------------------------------------
    Item {
        id: scena
        anchors.fill: parent

        // Cursor detection - see "HIDING" in the header. A handler, not
        // a MouseArea: it does not take events from the tiles underneath and gets hover
        // also over a tile that handles hover itself.
        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    chowanie.stop();
                    root.odsloniety = true;
                } else {
                    chowanie.restart();
                }
            }
        }

        // Pause dimming. A click on it exits the pause.
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: root.pauza ? Theme.pauzaPrzyciemnienie : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.pauza ? Theme.animPanelIn : Theme.animPanelOut
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Theme.easeOutQuint
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.pauza
                acceptedButtons: Qt.AllButtons
                onClicked: root.zamkniecieProszone()
            }
        }

        // Trigger strip right at the edge: a click on it
        // opens the pause, even when the row is hidden.
        MouseArea {
            x: 0
            y: root.height - root.pasekWywolawczy
            width: root.width
            height: root.pasekWywolawczy
            enabled: !root.pauza
            acceptedButtons: Qt.AllButtons
            onClicked: root.pauzaProszona()
        }

        // Pause lines - above the selected tile's name and below the row. Wider
        // than the row, so they read as a menu line and not a border.
        component Kreska: Rectangle {
            width: root.szerokoscRzedu + 240
            height: 1
            x: Math.round((root.width - width) / 2)
            color: Theme.accent
            opacity: root.pauza ? 0.55 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.pauza ? Theme.animPanelIn : Theme.animPanelOut
                }
            }
        }

        Kreska {
            id: kreskaNad
            y: root.rzadY - root.wysokoscNazwy - 6
        }

        Kreska {
            y: root.rzadY + Theme.kafelRozmiar + 9
        }

        // Content of the selected tile - above the line. Tiles with their own
        // content draw it themselves; the rest - a description (OpisKafla).
        OpisKafla {
            anchors.horizontalCenter: parent.horizontalCenter
            y: kreskaNad.y - 16 - height
            kafel: root.kafel
            widoczny: root.pauza && !root.maZawartosc(root.kafel)
        }

        Uzbrojenie {
            id: uzbrojenie
            anchors.horizontalCenter: parent.horizontalCenter
            y: kreskaNad.y - 16 - height
            widoczny: root.pauza && root.kafel.klucz === "uzbrojenie"
            aktywny: root.poziom === 1
            onUruchomiono: root.zamkniecieProszone()
        }

        Wiesci {
            id: wiesci
            anchors.horizontalCenter: parent.horizontalCenter
            y: kreskaNad.y - 16 - height
            widoczny: root.pauza && root.kafel.klucz === "wiesci"
            aktywny: root.poziom === 1
        }

        Ognisko {
            id: ognisko
            anchors.horizontalCenter: parent.horizontalCenter
            y: kreskaNad.y - 16 - height
            widoczny: root.pauza && root.kafel.klucz === "ognisko"
            aktywny: root.poziom === 1
            onWykonano: root.zamkniecieProszone()
        }

        Zebatka {
            id: zebatka
            anchors.horizontalCenter: parent.horizontalCenter
            y: kreskaNad.y - 16 - height
            widoczny: root.pauza && root.kafel.klucz === "zebatka"
            aktywny: root.poziom === 1
            // Mouse in the settings while the keyboard cursor is on the row -
            // the next arrow keys should reach the options, not switch tiles.
            onDotknieto: root.poziom = 1
        }

        Row {
            id: rzad

            x: root.rzadX
            y: root.rzadY
            spacing: Theme.kafelOdstep

            opacity: root.pokazany ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.pokazany ? Theme.animPanelIn : Theme.animPanelOut
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Theme.easeOutQuint
                }
            }

            // The model is the NUMBER of tiles, not the array itself: the array is
            // rebuilt on a language change, and a new array as the model would make
            // the Repeater recreate the tiles - they would flicker, because the images load
            // asynchronously. The number does not change, so the delegates stay.
            Repeater {
                model: root.kafle.length

                delegate: Kafel {
                    required property int index

                    klucz: root.kafle[index].klucz
                    nazwa: root.kafle[index].nazwa
                    wybrany: root.wybrany === index
                    licznik: root.kafle[index].klucz === "wiesci" ? Notifications.count : 0

                    onNajechano: root.wybrany = index

                    // One click uses the tile - see "MOUSE" in the header.
                    onKliknieto: {
                        root.wybrany = index;
                        root.uzyjWybranego();
                    }
                }
            }
        }
    }
}
