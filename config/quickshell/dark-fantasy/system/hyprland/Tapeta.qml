// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  HYPRLAND -> WALLPAPER - picking a file from ~/Obrazy/Tapety.
//
//  Arrows only SELECT a candidate - its preview is shown below the row.
//  The wallpaper is changed only by "Set as wallpaper": that rewrites
//  hyprpaper.conf and $tapeta in hyprlock.conf and restarts hyprpaper,
//  so flicking through the directory with arrows must not do that on
//  every step.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs
import qs.components
import qs.services
import qs.system

SekcjaOpcji {
    id: root

    readonly property var tapety: UstawieniaHyprlanda.tapety
    property int kandydat: Math.max(0, tapety.indexOf(UstawieniaHyprlanda.tapeta))

    // Picking a file replaces the binding above with a plain number, and this
    // section outlives closing the Cogwheel while the list is re-read on
    // every opening. So after the list changes, the candidate goes back to
    // the current wallpaper - otherwise it could point past the end.
    onTapetyChanged: kandydat = Math.max(0, tapety.indexOf(UstawieniaHyprlanda.tapeta))

    WierszOpcji {
        width: root.width
        etykieta: Tr.t("File", "Plik")
        typ: "wybor"
        opcje: root.tapety.map(t => ({ kod: t, nazwa: t }))
        indeks: root.kandydat
        dostepny: root.tapety.length > 0
        onZmieniono: function (i) { root.kandydat = i; }
    }

    // Candidate preview. Invisible to navigation - it is not an option row.
    Item {
        width: root.width
        height: 190

        Rectangle {
            anchors.centerIn: parent
            width: 304
            height: 190
            color: Theme.surface
            border.width: Theme.borderWidth
            border.color: Theme.border

            Image {
                anchors.fill: parent
                anchors.margins: Theme.borderWidth
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 608
                source: root.tapety.length > 0
                    ? "file://" + UstawieniaHyprlanda.katalogTapet + "/" + root.tapety[root.kandydat] : ""
            }
        }
    }

    WierszOpcji {
        width: root.width
        etykieta: root.tapety[root.kandydat] === UstawieniaHyprlanda.tapeta
            ? Tr.t("This is the current wallpaper", "To jest bieżąca tapeta")
            : Tr.t("Change the desktop and lock screen wallpaper", "Zmień tapetę pulpitu i blokady")
        typ: "przycisk"
        tekst: Tr.t("Set as wallpaper", "Ustaw jako tapetę")
        dostepny: root.kandydat < root.tapety.length && root.tapety[root.kandydat] !== UstawieniaHyprlanda.tapeta
        onUzyto: UstawieniaHyprlanda.ustawTapete(root.tapety[root.kandydat])
    }
}
