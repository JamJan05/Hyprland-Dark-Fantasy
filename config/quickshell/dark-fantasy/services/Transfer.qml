pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT - see Brightness.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  NETWORK TRANSFER - for the status buildup in the HUD.
//
//  Sum of bytes received and sent over all interfaces except
//  loopback (lo), from /proc/net/dev every 2 s. Speed is the difference
//  between reads divided by the time that actually elapsed - a Timer
//  is not an atomic clock, and under load it can run late.
//
//  Row format (after two header rows):
//      wlan0: rx_bytes rx_packets ... (8 rx fields) tx_bytes tx_packets ...
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQml
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real bajtyNaSekunde: 0

    // The HUD status lights up above 100 KiB/s. Below that it is background
    // noise (syncing, DNS queries), which is not worth showing.
    readonly property real progStatusu: 100 * 1024

    // Only real links are counted. A VPN (tun/wg) carries the same traffic
    // as the Wi-Fi under it, so with a VPN up the speed was counted twice;
    // bridges and veth pairs of containers likewise repeat other traffic.
    readonly property var wirtualny: /^(lo|tun|tap|wg|veth|docker|br-|virbr|vnet|tailscale|zt)/

    property real poprzednieBajty: -1
    property real poprzedniCzas: 0

    function przelicz(tekst: string): void {
        let bajty = 0;
        const wiersze = tekst.split("\n").slice(2);
        for (const w of wiersze) {
            const dwukropek = w.indexOf(":");
            if (dwukropek === -1) continue;
            if (root.wirtualny.test(w.slice(0, dwukropek).trim())) continue;
            const pola = w.slice(dwukropek + 1).trim().split(/\s+/).map(Number);
            bajty += (pola[0] || 0) + (pola[8] || 0);
        }

        const teraz = Date.now();
        if (poprzednieBajty >= 0 && teraz > poprzedniCzas) {
            // The counter can reset (the interface came back up) -
            // a negative difference would mean a negative speed.
            bajtyNaSekunde = Math.max(0, (bajty - poprzednieBajty) * 1000 / (teraz - poprzedniCzas));
        }
        poprzednieBajty = bajty;
        poprzedniCzas = teraz;
    }

    FileView {
        id: plik
        path: "/proc/net/dev"
        onLoaded: root.przelicz(text())
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: plik.reload()
    }
}
