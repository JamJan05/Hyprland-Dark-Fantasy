// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  OPTION SECTION - a column of WierszOpcji rows with arrow navigation.
//
//  Every section in the Cogwheel's right column (system/sekcje/, system/hyprland/)
//  is such a column. The section tracks which row is selected, ↑ ↓ moves
//  the selection, and all other keys are handed to the selected row.
//
//  Rows are collected from the column's children rather than listed by hand -
//  this way rows from a Repeater (floor names, app volumes) join the
//  navigation on their own. A row in text-editing mode gets all keys,
//  ↑ ↓ included.
//
//  "aktywna" = the keyboard cursor is in the right column. While it is on the
//  section list no row lights up - otherwise two selections would be visible
//  at once and it would be unclear where an arrow key lands.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs

Column {
    id: root

    property int wybrany: 0
    property bool aktywna: true

    // The mouse hovered a row - the Cogwheel then moves the cursor to this column.
    signal dotknieto()

    spacing: 2

    // Children that are option rows and are visible. "children" has a change
    // signal, so the list is recomputed when a Repeater adds a row.
    readonly property var wiersze: {
        const l = [];
        for (let i = 0; i < children.length; i++) {
            const c = children[i];
            if (c.visible && c.klawisz !== undefined && c.etykieta !== undefined) l.push(c);
        }
        return l;
    }

    readonly property var zaznaczonyWiersz:
        wiersze.length > 0 ? wiersze[Math.min(wybrany, wiersze.length - 1)] : null

    function odswiezZaznaczenie(): void {
        for (let i = 0; i < wiersze.length; i++) wiersze[i].zaznaczony = aktywna && i === wybrany;
    }

    onWybranyChanged: odswiezZaznaczenie()
    onAktywnaChanged: odswiezZaznaczenie()
    onWierszeChanged: {
        if (wybrany >= wiersze.length) wybrany = Math.max(0, wiersze.length - 1);
        odswiezZaznaczenie();
    }

    // Called by a row on mouse hover (see WierszOpcji).
    // Returns false when the row cannot be selected now.
    function wybierzWiersz(w: var): bool {
        const i = wiersze.indexOf(w);
        if (i < 0) return false;
        // While a row is being edited (waiting for keys, typing a name) the
        // mouse does not move the selection away from it - keys go to the
        // selected row, so they ended up in the row merely brushed by the
        // cursor, and the edited one kept Hyprland in capture until timeout.
        if (wiersze.some(x => x.edycja && x !== w)) return false;
        wybrany = i;
        dotknieto();
        return true;
    }

    function klawisz(zdarzenie: var): bool {
        // The row being edited gets the keys, wherever the selection is.
        const edytowany = wiersze.find(x => x.edycja);
        if (edytowany !== undefined) return edytowany.klawisz(zdarzenie);

        const w = zaznaczonyWiersz;
        if (w === null) return false;

        if (zdarzenie.key === Qt.Key_Up) {
            wybrany = Math.max(0, wybrany - 1);
            return true;
        }
        if (zdarzenie.key === Qt.Key_Down) {
            wybrany = Math.min(wiersze.length - 1, wybrany + 1);
            return true;
        }
        return w.klawisz(zdarzenie);
    }
}
