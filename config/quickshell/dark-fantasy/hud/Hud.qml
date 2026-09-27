// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  HUD - the left corner of the bar in Dark Souls style.
//
//      ┌────┐ ▐██████████████████░░░░░     HP       battery
//      │ II │ ▐███████████░░              FP       memory
//      └────┘ ▐█████████████░░░            stamina  CPU
//              ■ □ □    󰓡 ▀▀▀▒             floor desktops, statuses
//
//  A separate Quickshell layer window, not a Waybar module. Waybar cannot
//  draw three 6 px bars with an animated loss trail, nor an emblem
//  with a crossfade - GTK modules are at best text and an image.
//
//  The window has the IDENTICAL height, margin and outline as the bar frames
//  (Theme.barHeight, barMarginTop, barMarginSide, border), so it reads
//  as the left part of the bar. Waybar shifts the window title by Theme.hudWidth + 8 px.
//
//  RIGHT OF THE BARS, only on battery: how long it will last ("3 h 42 min").
//  The one number the HUD draws - it cannot be read from the bar, since the
//  fill says how much is left, not how fast it is going.
//
//  ---------------------------------------------------------------
//  BARS DISABLED
//
//  UstawieniaPowloki.hudBars = false hides the bars - the emblem and the desktop
//  row remain, vertically centred. CPU, memory and battery then
//  move as NUMBERS to the right side of Waybar (the custom/zasoby module).
//  The shell wakes that module with SIGRTMIN+11 every 5 s while the bars are
//  disabled, and once on every toggle. With the bars enabled
//  it sends nothing.
//
//  The signal goes through "pkill -RTMIN+11 -x waybar". An uncaught SIGRTMIN
//  KILLS the process, and Waybar only catches the numbers it has in its config - the number
//  must match the "signal" of the custom/zasoby module in config.jsonc.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.components
import qs.services

PanelWindow {
    id: root

    WlrLayershell.namespace: "quickshell-hud"

    // "top", like Waybar - the HUD should hide under a fullscreen window
    // together with the bar, not hang above a film.
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
    }

    margins {
        top: Theme.barMarginTop
        left: Theme.barMarginSide
    }

    // Waybar already reserves the space at the top of the screen; a second exclusive
    // zone would push windows down by another 38 px.
    exclusionMode: ExclusionMode.Ignore

    implicitWidth: Theme.hudWidth
    implicitHeight: Theme.barHeight

    color: "transparent"
    visible: true

    readonly property bool paski: UstawieniaPowloki.hudBars

    // IDLE INHIBIT.
    //
    // The inhibitor binds to a Wayland surface, so it needs a window -
    // the singleton services/Idle.qml has none. It used to live in the System Control
    // Center window; since stage 7 that window is no longer created, while the HUD exists for the whole
    // session and never disappears, so it serves just as well. The state is held by Idle.qml.
    IdleInhibitor {
        window: root
        enabled: Idle.inhibited
    }

    Rectangle {
        id: ramka
        anchors.fill: parent

        // Bar background and outline - a mirror of .modules-center in waybar/style.css.
        color: Qt.alpha(Theme.background, Theme.barOpacity)
        border.width: Theme.borderWidth
        border.color: Theme.border

        Szum {
            anchors.fill: parent
            anchors.margins: Theme.borderWidth
        }

        Godlo {
            id: godlo
            x: 4
            anchors.verticalCenter: parent.verticalCenter
            dymek: dymek
        }

        // The bars start 8 px to the right of the emblem. Vertically: 2 px from
        // the top frame, 22 px of bars (3 x 6 + 2 x 2), 2 px of spacing and the row
        // of 10 px squares - 36 px in total, the interior of the 38-pixel frame.
        HudBars {
            id: paskiStatystyk
            x: godlo.x + godlo.width + 8
            y: 2
            visible: root.paski
            dymek: dymek
        }

        Label {
            x: paskiStatystyk.x + paskiStatystyk.width + 8
            width: ramka.width - x - 6
            anchors.verticalCenter: paskiStatystyk.verticalCenter
            visible: root.paski && Battery.pozostalo > 0
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textMuted
            text: Battery.czas(Battery.pozostalo)
        }

        Row {
            id: dolnyRzad

            x: paskiStatystyk.x
            y: root.paski
                ? paskiStatystyk.y + paskiStatystyk.height + 2
                : (ramka.height - height) / 2
            height: 10
            spacing: 12

            PulpityPietra {
                anchors.verticalCenter: parent.verticalCenter
                dymek: dymek
            }

            // Network transfer. Bar on a logarithmic scale: 100 KiB/s is
            // an empty bar, 100 MiB/s - full. On a linear scale, loading a web
            // page and downloading a disc image would look the same.
            StatusNarastajacy {
                anchors.verticalCenter: parent.verticalCenter
                aktywny: Transfer.bajtyNaSekunde > Transfer.progStatusu
                ikona: Icons.transfer
                kolor: Theme.accent
                wartosc: Math.log10(Math.max(1, Transfer.bajtyNaSekunde / Transfer.progStatusu)) / 3
                opis: Tr.t("Network transfer", "Transfer sieci") + "\n" + root.predkosc(Transfer.bajtyNaSekunde)
                dymek: dymek
            }

            // CPU temperature: from the threshold (70 °C) the bar grows to full
            // at 95 °C, where the Ryzen starts throttling on its own.
            StatusNarastajacy {
                anchors.verticalCenter: parent.verticalCenter
                aktywny: Temperatura.dostepna && Temperatura.stopnie > Temperatura.progAlarmu
                ikona: Icons.thermometer
                kolor: Theme.ember
                wartosc: (Temperatura.stopnie - Temperatura.progAlarmu) / 25
                opis: Tr.t("CPU  ", "Procesor  ") + Math.round(Temperatura.stopnie) + " °C"
                dymek: dymek
            }
        }
    }

    Dymek {
        id: dymek
    }

    function predkosc(bajty: real): string {
        if (bajty >= 1048576)
            return Tr.dziesietna(bajty / 1048576, 1) + " MiB/s";
        return Math.round(bajty / 1024) + " KiB/s";
    }

    // ---------------------------------------------------------------
    //  NUMBERS ON WAYBAR - see "BARS DISABLED" in the header.
    // ---------------------------------------------------------------
    readonly property int sygnalPaska: 11

    Process {
        id: odswiezPasek
        command: ["pkill", "-RTMIN+" + root.sygnalPaska, "-x", "waybar"]
    }

    Timer {
        interval: 5000
        repeat: true
        running: !root.paski
        onTriggered: odswiezPasek.running = true
    }

    onPaskiChanged: odswiezPasek.running = true

    // JSON for custom/zasoby. Empty text hides the module.
    function liczby(): string {
        if (paski) return JSON.stringify({ text: "" });

        const zloto = String(Theme.accent);
        const zar = String(Theme.ember);
        const ikona = (glif, kolor) => "<span color='" + kolor + "'>" + glif + "</span>";
        const proc = v => Math.round(v * 100) + "%";

        const czesci = [
            ikona(Icons.cpu, zloto) + " " + proc(Cpu.uzycie),
            ikona(Icons.memory, zloto) + " " + proc(Memory.uzycie)
        ];
        const dymekPaska = [
            Tr.t("CPU: ", "Procesor: ") + proc(Cpu.uzycie) + " (" + Cpu.watki + " "
                + Tr.forma(Cpu.watki, "thread", "threads", "wątek", "wątki", "wątków") + ")",
            Tr.t("Memory: ", "Pamięć: ") + Memory.uzytaGiB.toFixed(1) + " / " + Memory.calkowitaGiB.toFixed(1) + " GiB"
        ];

        let krytyczna = false;
        if (Battery.obecna) {
            // Threshold from the old "battery" module: critical 12 %.
            krytyczna = !Battery.laduje && !Battery.naKablu && Battery.poziom <= 0.12;
            czesci.push(ikona(Icons.battery(Battery.poziom, Battery.laduje, Battery.naKablu),
                              krytyczna ? zar : zloto) + " " + proc(Battery.poziom));
            if (Battery.pozostalo > 0) czesci[czesci.length - 1] += " (" + Battery.czas(Battery.pozostalo) + ")";
            dymekPaska.push(Tr.t("Battery: ", "Bateria: ") + proc(Battery.poziom)
                + (Battery.laduje ? Tr.t(", charging", ", ładowanie")
                   : Battery.naKablu ? Tr.t(", plugged in", ", z sieci")
                   : Battery.pozostalo > 0 ? Tr.t(", ", ", zostało ") + Battery.czas(Battery.pozostalo)
                     + Tr.t(" left", "") : ""));
        }

        return JSON.stringify({
            text: czesci.join("   "),
            class: krytyczna ? "krytyczna" : "",
            tooltip: dymekPaska.join("\n")
        });
    }
}
