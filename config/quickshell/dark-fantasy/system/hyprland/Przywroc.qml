// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  HYPRLAND -> RESTORE DEFAULTS.
//
//  Removes ~/.config/hypr/ustawienia.lua and reloads Hyprland - everything
//  returns to the values from hyprland.lua. The wallpaper is not affected:
//  changing it rewrites hyprpaper.conf, not the settings file.
//
//  Confirmation as in the game's menus: the button turns into the question
//  "Restore defaults?" with two rows, Yes and No. The cursor lands on No, so
//  a double Enter does not wipe the settings by accident. Leaving the column
//  (Esc, mouse on the section list) or the section cancels the question.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs
import qs.components
import qs.services
import qs.system

SekcjaOpcji {
    id: root

    property bool pyta: false

    function zapytaj(): void {
        pyta = true;
        wybrany = 1;    // "No"
    }

    function anuluj(): void {
        pyta = false;
        wybrany = 0;
    }

    onVisibleChanged: if (!visible) anuluj()

    // A separate Connections, not onAktywnaChanged: SekcjaOpcji already
    // handles that signal itself.
    Connections {
        target: root
        function onAktywnaChanged(): void {
            if (!root.aktywna && root.pyta) root.anuluj();
        }
    }

    Label {
        width: root.width
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        color: Theme.textMuted
        bottomPadding: Theme.spacingMd
        text: Tr.t("Gaps, border, blur, animations, touchpad, keyboard layout, "
                 + "monitor and floors will return to the values from hyprland.lua.",
                 "Odstępy, ramka, rozmycie, animacje, touchpad, układ klawiatury, "
                 + "ekran i piętra wrócą do wartości z hyprland.lua.")
    }

    WierszOpcji {
        width: root.width
        visible: !root.pyta
        etykieta: Tr.t("All Hyprland settings", "Wszystkie ustawienia Hyprlanda")
        typ: "przycisk"
        tekst: Tr.t("Restore defaults", "Przywróć domyślne")
        onUzyto: root.zapytaj()
    }

    Tytul {
        width: root.width
        visible: root.pyta
        horizontalAlignment: Text.AlignHCenter
        topPadding: Theme.spacingSm
        bottomPadding: Theme.spacingMd
        text: Tr.t("Restore defaults?", "Przywrócić domyślne?")
    }

    WierszOpcji {
        width: root.width
        visible: root.pyta
        etykieta: Tr.t("Yes", "Tak")
        typ: "przycisk"
        tekst: Tr.t("restore", "przywróć")
        onUzyto: {
            root.anuluj();
            UstawieniaHyprlanda.przywrocDomyslne();
        }
    }

    WierszOpcji {
        width: root.width
        visible: root.pyta
        etykieta: Tr.t("No", "Nie")
        typ: "przycisk"
        tekst: Tr.t("back", "wróć")
        onUzyto: root.anuluj()
    }
}
