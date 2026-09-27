// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  THREE STAT BARS - HP, FP and stamina.
//
//      HP       battery       length from battery capacity
//      FP       RAM           length from amount of memory
//      stamina  CPU           length from thread count
//
//  The fill is the CURRENT state (battery level, used memory,
//  load), and the LENGTH - the computer's "stats". A stronger machine has
//  longer bars, like a character with more points in attributes.
//  The scales and the upper length limit are in Theme.qml (hudPxPer*, hudBarMax).
//
//  Numbers are not drawn - the tooltip shows them on hover.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import qs
import qs.components
import qs.services

Column {
    id: root

    property Dymek dymek: null

    spacing: Theme.hudBarGap

    // Length from the stats, clamped to what fits in the corner. Lower
    // limit 40 px - a bar shorter than a build-up status would not read
    // as a bar.
    function dlugosc(px: real): real {
        return Math.max(40, Math.min(Theme.hudBarMax, px));
    }

    function procent(v: real): string {
        return Math.round(v * 100) + Tr.t("%", " %");
    }

    function gib(v: real): string {
        return Tr.dziesietna(v, 1);
    }

    function podpowiedz(pasek: Item, tekst: string, hovered: bool): void {
        if (!dymek) return;
        if (hovered) dymek.pokaz(pasek, tekst);
        else dymek.schowaj(pasek);
    }

    // ---------------- HP - battery ----------------
    StatBar {
        id: hp

        // Visible length = design scale x health: a worn battery
        // has a shorter bar. No battery - a full bar of fixed length.
        length: Battery.obecna
            ? root.dlugosc(Battery.projektWh * Theme.hudPxPerWh) * Battery.kondycja
            : Theme.hudHpBezBaterii
        value: Battery.obecna ? Battery.poziom : 1
        fillColor: Theme.hudHp

        // Charging = ember outline.
        alarm: Battery.laduje

        HoverHandler {
            onHoveredChanged: root.podpowiedz(hp, !Battery.obecna
                ? Tr.t("No battery\nplugged in", "Brak baterii\nzasilanie z sieci")
                : Tr.t("Battery  ", "Bateria  ") + root.procent(Battery.poziom) + "\n"
                  + (Battery.laduje ? Tr.t("charging", "ładowanie")
                     : Battery.naKablu ? Tr.t("plugged in", "zasilanie z sieci")
                     : Battery.pozostalo > 0
                       ? Tr.t("on battery, ", "na baterii, zostało ") + Battery.czas(Battery.pozostalo)
                         + Tr.t(" left", "")
                     : Tr.t("on battery", "na baterii"))
                  + "\n" + Tr.t("health ", "kondycja ") + root.procent(Battery.kondycja)
                  + " (" + Math.round(Battery.projektWh) + Tr.t(" Wh design)", " Wh projektowo)"), hovered)
        }
    }

    // ---------------- FP - memory ----------------
    StatBar {
        id: fp

        length: root.dlugosc(Memory.calkowitaGiB * Theme.hudPxPerGiB)
        value: Memory.uzycie
        fillColor: Theme.hudFp

        HoverHandler {
            onHoveredChanged: root.podpowiedz(fp,
                Tr.t("Memory  ", "Pamięć  ") + root.procent(Memory.uzycie) + "\n"
                + root.gib(Memory.uzytaGiB) + Tr.t(" of ", " z ") + root.gib(Memory.calkowitaGiB) + " GiB", hovered)
        }
    }

    // ---------------- stamina - CPU ----------------
    StatBar {
        id: stamina

        length: root.dlugosc(Cpu.watki * Theme.hudPxPerThread)
        value: Cpu.uzycie
        fillColor: Theme.hudStamina

        HoverHandler {
            onHoveredChanged: root.podpowiedz(stamina,
                Tr.t("CPU  ", "Procesor  ") + root.procent(Cpu.uzycie) + "\n" + Cpu.watki + " "
                + Tr.forma(Cpu.watki, "thread", "threads", "wątek", "wątki", "wątków"), hovered)
        }
    }
}
