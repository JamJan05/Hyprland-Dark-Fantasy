pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT - see Brightness.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  HYPRLAND SETTINGS - model of the "Hyprland" section in the Cogwheel.
//
//  ---------------------------------------------------------------
//  HOW IT WORKS
//
//  THE GUI DOES NOT EDIT hyprland.lua. It owns a single file,
//  ~/.config/hypr/ustawienia.lua, which hyprland.lua loads at the very
//  end (rationale there, in the last section). Every change in the Cogwheel:
//
//    1. goes IMMEDIATELY to Hyprland via "hyprctl eval <lua>" - the effect
//       is visible while dragging the slider, without reloading the configuration;
//    2. lands in ustawienia.lua - after a moment of quiet (600 ms), not on
//       every slider step, because a write rewrites the whole file.
//
//  There is no "hyprctl keyword" here: with a Lua configuration it does not work (reading
//  after a write returns the old value - described at force_split in hyprland.lua).
//
//  "Restore defaults" = deleting the file + "hyprctl reload".
//
//  ---------------------------------------------------------------
//  WHERE THE VALUES COME FROM
//
//  Hyprland options (gaps, border, blur...) - from "hyprctl getoption",
//  i.e. from what the compositor really has. Whatever getoption does not know
//  (animation speed, touchpad sensitivity as a device rule, floors,
//  monitor scale) is remembered by the settings file itself: its second line is
//  "-- stan: {json}" - the same state the file is generated from.
//
//  ---------------------------------------------------------------
//  PATHS FOLLOW XDG_CONFIG_HOME
//
//  Same as in hyprland.lua. The test stand gets its own directory
//  and does not touch the live session's settings, hyprpaper.conf or hyprlock.conf.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQml
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ---------------------------------------------------------------
    //  PATHS
    // ---------------------------------------------------------------
    readonly property string katalogKonfigu: {
        const x = Quickshell.env("XDG_CONFIG_HOME");
        return (x ? x : Quickshell.env("HOME") + "/.config");
    }
    readonly property string sciezkaUstawien: katalogKonfigu + "/hypr/ustawienia.lua"
    readonly property string sciezkaHyprpaper: katalogKonfigu + "/hypr/hyprpaper.conf"
    readonly property string sciezkaHyprlock: katalogKonfigu + "/hypr/hyprlock.conf"
    // Wallpaper folder: <XDG Pictures>/Wallpapers, or an existing
    // <XDG Pictures>/Tapety. Resolved together with the file list
    // (odczytTapet); this is only the value before the first read.
    property string katalogTapet: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    // ---------------------------------------------------------------
    //  OPTIONS READ VIA GETOPTION
    //
    //  klucz  - name for "hyprctl getoption"
    //  lua    - path in hl.config({...})
    //  typ    - int / float / bool / str
    // ---------------------------------------------------------------
    readonly property var opcje: [
        { klucz: "general:gaps_in",               lua: ["general", "gaps_in"],               typ: "int" },
        { klucz: "general:gaps_out",              lua: ["general", "gaps_out"],              typ: "int" },
        { klucz: "general:border_size",           lua: ["general", "border_size"],           typ: "int" },
        { klucz: "decoration:blur:enabled",       lua: ["decoration", "blur", "enabled"],    typ: "bool" },
        { klucz: "decoration:blur:size",          lua: ["decoration", "blur", "size"],       typ: "int" },
        { klucz: "decoration:inactive_opacity",   lua: ["decoration", "inactive_opacity"],   typ: "float" },
        { klucz: "decoration:dim_inactive",       lua: ["decoration", "dim_inactive"],       typ: "bool" },
        { klucz: "decoration:dim_strength",       lua: ["decoration", "dim_strength"],       typ: "float" },
        { klucz: "animations:enabled",            lua: ["animations", "enabled"],            typ: "bool" },
        { klucz: "input:touchpad:natural_scroll", lua: ["input", "touchpad", "natural_scroll"], typ: "bool" },
        { klucz: "input:kb_layout",               lua: ["input", "kb_layout"],               typ: "str" }
    ]

    // Current values of the options from the list above: { "general:gaps_in": 5, ... }.
    // The object is replaced as a whole - QML does not see a change of a field inside an object.
    property var wartosci: ({})

    // State saved in the file (see "WHERE THE VALUES COME FROM"). "opcje" contains only
    // the keys the user has changed - the rest stays as in hyprland.lua.
    property var stan: domyslnyStan()

    function domyslnyStan(): var {
        return { opcje: {}, tempo: 1, czuloscTouchpada: null, pietra: 10, nazwy: [],
                 gesty: true, monitor: null, drugiMonitor: null,
                 // zmiany: { id: keys } - shortcuts moved away from their default,
                 // wlasne: [{ klawisze, nazwa, komenda }] - application shortcuts.
                 skroty: { zmiany: {}, wlasne: [] } };
    }

    property bool gotowe: false

    // ---------------------------------------------------------------
    //  READING - on every Cogwheel opening (odswiez) and after a restore
    // ---------------------------------------------------------------
    function odswiez(): void {
        odczytOpcji.running = true;
        odczytMonitorow.running = true;
        odczytUrzadzen.running = true;
        odczytSkrotow.running = true;
        odczytTapet.running = true;
        // When a write is pending, the state in memory is newer than the file. Reading
        // the file would replace it with the old one (or the default one, when the file does not
        // exist yet), and the pending write would persist that replacement - all it takes is closing
        // and reopening the Cogwheel within 600 ms of the change.
        if (!zapis.running) plikUstawien.reload();
        plikHyprpaper.reload();
    }

    Component.onCompleted: odswiez()

    // One process for all options: getoption one after another, each response
    // on a single line (jq -c). This is a read once per panel opening, not a loop.
    Process {
        id: odczytOpcji
        command: ["sh", "-c",
            "for k in " + root.opcje.map(o => o.klucz).join(" ")
            + "; do hyprctl getoption \"$k\" -j | jq -c .; done"]
        stdout: StdioCollector { id: wyjscieOpcji }
        onExited: {
            const w = {};
            for (const wiersz of wyjscieOpcji.text.trim().split("\n")) {
                let o;
                try { o = JSON.parse(wiersz); } catch (e) { continue; }
                if (o.int !== undefined) w[o.option] = o.int;
                else if (o.float !== undefined) w[o.option] = o.float;
                else if (o.bool !== undefined) w[o.option] = o.bool;
                // Gaps come as CSS "5 5 5 5" - we take the first
                // number; the Cogwheel sets all four sides at once.
                else if (o.css !== undefined) w[o.option] = parseInt(o.css, 10);
                else if (o.str !== undefined) w[o.option] = o.str;
            }
            root.wartosci = w;
            root.gotowe = true;
        }
    }

    // ---------------------------------------------------------------
    //  CHANGES
    // ---------------------------------------------------------------
    // Not "eval" - that is the name of a built-in JavaScript function.
    function wykonajLua(lua: string): void {
        Quickshell.execDetached(["hyprctl", "eval", lua]);
    }

    // A value as a Lua literal. Strings via JSON.stringify - the quote
    // and the slash are escaped the same way in JSON and in Lua, and JSON
    // leaves Polish letters unchanged.
    function literal(v: var): string {
        if (typeof v === "string") return JSON.stringify(v);
        if (typeof v === "boolean") return v ? "true" : "false";
        return String(v);
    }

    // { a = { b = 5 } } from ["a", "b"] and 5.
    function tabelaLua(sciezka: var, v: var): string {
        let s = literal(v);
        for (let i = sciezka.length - 1; i >= 0; i--) s = "{ " + sciezka[i] + " = " + s + " }";
        return s;
    }

    function opcja(klucz: string): var {
        for (const o of opcje) if (o.klucz === klucz) return o;
        return null;
    }

    function ustaw(klucz: string, wartosc: var): void {
        const o = opcja(klucz);
        if (o === null) return;
        if (o.typ === "int") wartosc = Math.round(wartosc);
        if (o.typ === "float") wartosc = Math.round(wartosc * 100) / 100;

        const w = Object.assign({}, wartosci);
        w[klucz] = wartosc;
        wartosci = w;

        const s = Object.assign({}, stan);
        s.opcje = Object.assign({}, stan.opcje);
        s.opcje[klucz] = wartosc;
        stan = s;

        wykonajLua("hl.config(" + tabelaLua(o.lua, wartosc) + ")");
        zapis.restart();
    }

    function zmienStan(pole: string, wartosc: var): void {
        const s = Object.assign({}, stan);
        s[pole] = wartosc;
        stan = s;
        zapis.restart();
    }

    // Animation speed: 1 = timings from hyprland.lua, 2 = twice as fast.
    function ustawTempo(tempo: real): void {
        tempo = Math.round(tempo * 20) / 20;
        zmienStan("tempo", tempo);
        wykonajLua("ustawAnimacje(" + tempo + ")");
    }

    // ---------------- TOUCHPAD ----------------
    // Sensitivity as a device rule - input.sensitivity would also change
    // the mouse and the TrackPoint. The touchpad name comes from "hyprctl devices".
    property string nazwaTouchpada: ""

    Process {
        id: odczytUrzadzen
        command: ["sh", "-c", "hyprctl devices -j | jq -r '.mice[].name'"]
        stdout: StdioCollector { id: wyjscieUrzadzen }
        onExited: {
            const t = wyjscieUrzadzen.text.split("\n").find(n => /touchpad/i.test(n));
            root.nazwaTouchpada = t ? t : "";
        }
    }

    readonly property real czuloscTouchpada: stan.czuloscTouchpada === null ? 0 : stan.czuloscTouchpada

    function ustawCzuloscTouchpada(v: real): void {
        if (nazwaTouchpada === "") return;
        v = Math.round(v * 20) / 20;
        zmienStan("czuloscTouchpada", v);
        wykonajLua("hl.device({ name = " + literal(nazwaTouchpada) + ", sensitivity = " + v + " })");
    }

    // ---------------- KEYBOARD LAYOUT ----------------
    // A short list of the most common layouts instead of ~100 entries from xkb -
    // scrolling with the arrow keys through every layout in the world makes no sense.
    readonly property var ukladyKlawiatury: [
        { kod: "pl", nazwa: Tr.t("Polish", "polski") }, { kod: "us", nazwa: Tr.t("English (US)", "angielski (USA)") },
        { kod: "gb", nazwa: Tr.t("English (UK)", "angielski (UK)") }, { kod: "de", nazwa: Tr.t("German", "niemiecki") },
        { kod: "fr", nazwa: Tr.t("French", "francuski") }, { kod: "es", nazwa: Tr.t("Spanish", "hiszpański") },
        { kod: "it", nazwa: Tr.t("Italian", "włoski") }, { kod: "cz", nazwa: Tr.t("Czech", "czeski") },
        { kod: "sk", nazwa: Tr.t("Slovak", "słowacki") }, { kod: "ua", nazwa: Tr.t("Ukrainian", "ukraiński") }
    ]

    // ---------------- FLOORS ----------------
    function wyslijPietra(): void {
        const nazwy = "{ " + stan.nazwy.map(n => literal(n || "")).join(", ") + " }";
        wykonajLua("floors.ustaw({ pietra = " + stan.pietra + ", nazwy = " + nazwy
             + ", gesty = " + literal(stan.gesty) + " })");
    }

    function ustawPietra(n: int): void {
        zmienStan("pietra", Math.max(1, Math.min(10, n)));
        wyslijPietra();
    }

    function ustawNazwePietra(i: int, nazwa: string): void {
        const nazwy = stan.nazwy.slice();
        while (nazwy.length <= i) nazwy.push("");
        nazwy[i] = nazwa.trim();
        zmienStan("nazwy", nazwy);
        wyslijPietra();
    }

    function ustawGesty(wl: bool): void {
        zmienStan("gesty", wl);
        wyslijPietra();
    }

    // ---------------- MONITORS ----------------
    property var monitory: []

    Process {
        id: odczytMonitorow
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector { id: wyjscieMonitorow }
        onExited: {
            try { root.monitory = JSON.parse(wyjscieMonitorow.text); } catch (e) { root.monitory = []; }
        }
    }

    readonly property var monitor: monitory.length > 0 ? monitory[0] : null
    readonly property var drugi: monitory.length > 1 ? monitory[1] : null

    // "CLEAN" SCALES - the resolution divided by the scale must give an integer
    // on both axes, otherwise Hyprland silently swaps the scale for the
    // nearest valid one (comment at hl.monitor in hyprland.lua). Computed
    // in hundredths, so as not to run into floating-point
    // rounding errors.
    readonly property var skale: {
        if (!monitor) return [];
        const w = monitor.width, h = monitor.height, wynik = [];
        for (let k = 50; k <= 300; k++) {
            if ((w * 100) % k === 0 && (h * 100) % k === 0) wynik.push(k / 100);
        }
        return wynik;
    }

    // Refresh rates available at the current resolution.
    readonly property var odswiezania: {
        if (!monitor) return [];
        const wynik = [];
        for (const m of monitor.availableModes) {
            const r = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(m);
            if (r && Number(r[1]) === monitor.width && Number(r[2]) === monitor.height) {
                const hz = Number(r[3]);
                if (wynik.indexOf(hz) === -1) wynik.push(hz);
            }
        }
        return wynik.sort((a, b) => b - a);
    }

    function wyslijMonitor(): void {
        const m = stan.monitor;
        if (!m) return;
        wykonajLua("hl.monitor({ output = " + literal(m.nazwa) + ", mode = " + literal(m.tryb)
             + ", position = \"0x0\", scale = " + literal(String(m.skala)) + " })");
    }

    // The saved state only counts for the same output. With another monitor
    // first in the list (an external screen plugged in), reusing it sent
    // the old output's name with this monitor's mode - the wrong screen got
    // an invalid mode and the visible one did not change.
    function stanMonitora(): var {
        if (stan.monitor && stan.monitor.nazwa === monitor.name) return Object.assign({}, stan.monitor);
        return { nazwa: monitor.name,
                 tryb: monitor.width + "x" + monitor.height + "@" + monitor.refreshRate.toFixed(2),
                 skala: monitor.scale };
    }

    function ustawSkale(s: real): void {
        if (!monitor) return;
        const m = stanMonitora();
        m.skala = s;
        zmienStan("monitor", m);
        wyslijMonitor();
    }

    function ustawOdswiezanie(hz: real): void {
        if (!monitor) return;
        const m = stanMonitora();
        m.tryb = monitor.width + "x" + monitor.height + "@" + hz.toFixed(2);
        zmienStan("monitor", m);
        wyslijMonitor();
    }

    // Second monitor: on which side of the first one. "auto-right" and its siblings
    // are positions that Hyprland computes itself from the screen sizes.
    readonly property var pozycjeDrugiego: [
        { kod: "auto-right", nazwa: Tr.t("to the right", "po prawej") }, { kod: "auto-left", nazwa: Tr.t("to the left", "po lewej") },
        { kod: "auto-up", nazwa: Tr.t("above", "nad") }, { kod: "auto-down", nazwa: Tr.t("below", "pod") }
    ]

    function ustawPozycjeDrugiego(kod: string): void {
        if (!drugi) return;
        zmienStan("drugiMonitor", { nazwa: drugi.name, pozycja: kod });
        wykonajLua("hl.monitor({ output = " + literal(drugi.name) + ", mode = \"preferred\", position = "
             + literal(kod) + ", scale = \"auto\" })");
    }

    // ---------------- WALLPAPER ----------------
    property var tapety: []
    property string tapeta: ""      // file name of the current wallpaper

    Process {
        id: odczytTapet
        // First output line = the folder, the rest = image files in it.
        command: ["sh", "-c",
            "k=$(xdg-user-dir PICTURES 2>/dev/null); "
            + "[ -z \"$k\" ] || [ \"$k\" = \"$HOME\" ] && k=\"$HOME/Pictures\"; "
            + "d=\"$k/Wallpapers\"; [ ! -d \"$d\" ] && [ -d \"$k/Tapety\" ] && d=\"$k/Tapety\"; "
            + "echo \"$d\"; ls -1 \"$d\" 2>/dev/null | grep -iE '\\.(png|jpe?g|webp)$'"]
        stdout: StdioCollector { id: wyjscieTapet }
        onExited: {
            const linie = wyjscieTapet.text.split("\n").filter(l => l !== "");
            if (linie.length > 0) root.katalogTapet = linie[0];
            root.tapety = linie.slice(1);
        }
    }

    // hyprpaper.conf and hyprlock.conf are regular files copied in by install.sh, so an
    // atomic write (temporary file + rename) would work too. atomicWrites: false stays
    // anyway: it is harmless for a regular file, and it is still correct if someone
    // links these files into a repository by hand - an atomic write would replace the
    // symlink with a regular file and the change would silently stop reaching the repo.
    FileView {
        id: plikHyprpaper
        path: root.sciezkaHyprpaper
        atomicWrites: false
        printErrors: false
        onLoaded: {
            const r = /^\s*path\s*=\s*(.+)$/m.exec(text());
            root.tapeta = r ? r[1].trim().replace(/##/g, "#").split("/").pop() : "";
        }
    }

    FileView {
        id: plikHyprlock
        path: root.sciezkaHyprlock
        atomicWrites: false
        printErrors: false
    }

    function ustawTapete(plik: string): void {
        // Only a file from the current list. A stale index in the Cogwheel
        // used to pass undefined here - the "string" annotation turns it into
        // "undefined", and ".../Wallpapers/undefined" ended up in both
        // configs: black desktop and lock screen.
        if (tapety.indexOf(plik) < 0) return;

        const dom = Quickshell.env("HOME");
        const pelna = katalogTapet + "/" + plik;
        // "#" starts a comment in hyprlang; "##" is a literal "#". Without
        // this "a#b.png" was cut to "a" and no wallpaper showed.
        const sciezka = (pelna.startsWith(dom + "/") ? "~" + pelna.slice(dom.length) : pelna)
            .replace(/#/g, "##");

        const hp = plikHyprpaper.text();
        if (/^\s*path\s*=/m.test(hp)) {
            plikHyprpaper.setText(hp.replace(/^(\s*path\s*=\s*).*$/m, (_, a) => a + sciezka));
        }
        // $tapeta in hyprlock - the tilde works (comment in hyprlock.conf).
        plikHyprlock.reload();
        plikHyprlock.waitForJob();
        const hl = plikHyprlock.text();
        if (/^\$tapeta\s*=/m.test(hl)) {
            plikHyprlock.setText(hl.replace(/^(\$tapeta\s*=\s*).*$/m, (_, a) => a + sciezka));
        }
        tapeta = plik;

        // hyprpaper 0.8 no longer has a simple command for changing the wallpaper via
        // hyprctl, so it is restarted with the new file. Only the hyprpaper
        // of THIS session (same WAYLAND_DISPLAY) is killed - on the test
        // stand the live wallpaper stays untouched.
        Quickshell.execDetached(["sh", "-c",
            "for p in $(pgrep -x hyprpaper); do tr '\\0' '\\n' </proc/$p/environ "
            + "| grep -qx \"WAYLAND_DISPLAY=$WAYLAND_DISPLAY\" && kill $p; done; "
            + "sleep 0.4; setsid -f hyprpaper >/dev/null 2>&1"]);
    }

    // ---------------- SHORTCUTS ----------------
    //
    // Three kinds, see "EDITABLE SHORTCUTS" in hyprland.lua:
    //   edytowalne  registered with skrot() - can be moved to other keys
    //   wlasne      application shortcuts added here
    //   skroty      the rest (desktops, mouse, media keys) - view only
    //
    // The first two come from skroty.json, which hyprland.lua writes into the
    // instance directory after every change; the fixed ones from "hyprctl binds".

    // Raw binds from "hyprctl binds" of the main map (only those with a description).
    property var bindy: []

    // skroty.json: { edytowalne: [{ id, klawisze, domyslne, opis }], wlasne: [{ klawisze, nazwa, komenda }] }
    property var listaSkrotow: ({ edytowalne: [], wlasne: [] })

    readonly property var edytowalne: listaSkrotow.edytowalne || []
    readonly property var wlasne: listaSkrotow.wlasne || []

    // Modifier mask bits per wlr/xkb: 1 SHIFT, 4 CTRL, 8 ALT, 64 SUPER.
    readonly property var mody: [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]]

    // "SUPER + SHIFT + s" -> { maska: 65, klawisz: "s" } - the same comparison
    // Hyprland makes (modmask + key, case does not matter).
    function rozbierz(klawisze: string): var {
        const czesci = klawisze.split("+").map(c => c.trim()).filter(c => c !== "");
        let maska = 0;
        for (const c of czesci.slice(0, -1)) {
            const d = c.toUpperCase();
            if (d === "SUPER" || d === "WIN" || d === "LOGO" || d === "META" || d === "MOD4") maska |= 64;
            else if (d === "CTRL" || d === "CONTROL") maska |= 4;
            else if (d === "ALT" || d === "MOD1") maska |= 8;
            else if (d === "SHIFT") maska |= 1;
        }
        return { maska: maska, klawisz: (czesci.length > 0 ? czesci[czesci.length - 1] : "").toLowerCase() };
    }

    function tenSam(a: var, b: var): bool {
        return a.maska === b.maska && a.klawisz === b.klawisz;
    }

    // Keys for display: modifiers as they are, the key by its name on the keyboard.
    function ladnie(klawisze: string): string {
        const r = rozbierz(klawisze);
        const czesci = klawisze.split("+").map(c => c.trim());
        const klawisz = czesci[czesci.length - 1];
        return mody.filter(m => (r.maska & m[0]) !== 0).map(m => m[1])
            .concat([nazwyKlawiszy[klawisz] ?? klawisz]).join(" + ");
    }

    // The fixed shortcuts: every described bind of the main map that is
    // neither editable nor an application shortcut. A binding, not an
    // assignment in onExited - key names follow a language change without re-reading.
    readonly property var skroty: {
        const zajete = edytowalne.map(e => rozbierz(e.klawisze))
            .concat(wlasne.map(w => rozbierz(w.klawisze)));
        const nazwy = nazwyKlawiszy;
        return bindy
            .filter(b => !zajete.some(z => tenSam(z, { maska: b.modmask, klawisz: b.key.toLowerCase() })))
            .map(b => ({
                klawisze: mody.filter(m => (b.modmask & m[0]) !== 0).map(m => m[1])
                              .concat([nazwy[b.key] ?? b.key]).join(" + "),
                opis: b.description
            }));
    }

    // Which bind already sits on these keys - its description, or "" when they
    // are free. "pomin" = the keys of the shortcut being changed, which may
    // keep its own keys. Checked against everything Hyprland has, not only
    // the described binds.
    property var wszystkieBindy: []

    function kolizja(klawisze: string, pomin: string): string {
        const r = rozbierz(klawisze);
        if (pomin !== "" && tenSam(r, rozbierz(pomin))) return "";
        for (const b of wszystkieBindy) {
            if (tenSam(r, { maska: b.modmask, klawisz: b.key.toLowerCase() }))
                return b.description !== "" ? b.description : Tr.t("another shortcut", "inny skrót");
        }
        return "";
    }

    function zapiszZmianySkrotow(zmiany: var, wlasneStan: var): void {
        zmienStan("skroty", { zmiany: zmiany, wlasne: wlasneStan });
        ponownyOdczytSkrotow.restart();
    }

    // An editable shortcut on new keys. Back on its default keys it drops out
    // of the settings file.
    function zmienSkrot(id: string, klawisze: string): void {
        const e = edytowalne.find(x => x.id === id);
        if (!e) return;
        const zmiany = Object.assign({}, stan.skroty.zmiany);
        if (tenSam(rozbierz(klawisze), rozbierz(e.domyslne))) delete zmiany[id];
        else zmiany[id] = klawisze;
        wykonajLua("przypiszSkrot(" + literal(id) + ", " + literal(klawisze) + ")");
        zapiszZmianySkrotow(zmiany, stan.skroty.wlasne);
    }

    function przywrocSkrot(id: string): void {
        const e = edytowalne.find(x => x.id === id);
        if (e) zmienSkrot(id, e.domyslne);
    }

    // Application shortcut. "gtk-launch <desktop id>" starts the program the
    // same way the Arsenal does (Exec, Terminal=, field codes), without
    // copying the Exec line into the settings file. The id is checked, because
    // it goes into a shell command.
    function komendaAplikacji(wpis: var): string {
        if (!wpis) return "";
        const id = String(wpis.id).replace(/\.desktop$/, "");
        return /^[A-Za-z0-9._-]+$/.test(id) ? "gtk-launch " + id : "";
    }

    function dodajWlasny(klawisze: string, nazwa: string, komenda: string): void {
        if (klawisze === "" || komenda === "") return;
        const lista = stan.skroty.wlasne.filter(w => !tenSam(rozbierz(w.klawisze), rozbierz(klawisze)));
        lista.push({ klawisze: klawisze, nazwa: nazwa, komenda: komenda });
        wykonajLua("wlasnySkrot(" + literal(klawisze) + ", " + literal(komenda) + ", " + literal(nazwa) + ")");
        zapiszZmianySkrotow(stan.skroty.zmiany, lista);
    }

    function usunWlasny(klawisze: string): void {
        wykonajLua("usunWlasnySkrot(" + literal(klawisze) + ")");
        zapiszZmianySkrotow(stan.skroty.zmiany,
            stan.skroty.wlasne.filter(w => w.klawisze !== klawisze));
    }

    function przeniesWlasny(stare: string, nowe: string): void {
        const w = stan.skroty.wlasne.find(x => x.klawisze === stare);
        if (!w) return;
        wykonajLua("usunWlasnySkrot(" + literal(stare) + ")");
        const lista = stan.skroty.wlasne.filter(x => x.klawisze !== stare);
        zapiszZmianySkrotow(stan.skroty.zmiany, lista);
        dodajWlasny(nowe, w.nazwa, w.komenda);
    }

    // Capturing keys: Hyprland goes into the empty "df-przechwyt" submap
    // (hyprland.lua), so no bind fires and the shell gets every combination.
    property bool przechwytywanie: false

    function przechwytuj(wl: bool): void {
        if (wl === przechwytywanie) return;
        przechwytywanie = wl;
        wykonajLua("hl.dispatch(hl.dsp.submap(" + literal(wl ? "df-przechwyt" : "reset") + "))");
    }

    // A key event -> keys in Hyprland's notation ("SUPER + SHIFT + T"), or ""
    // while only a modifier is held or for a key that cannot be bound.
    function klawiszeZeZdarzenia(z: var): string {
        const nazwa = nazwaKlawisza(z.key);
        if (nazwa === "") return "";
        const m = [];
        if (z.modifiers & Qt.MetaModifier) m.push("SUPER");
        if (z.modifiers & Qt.ControlModifier) m.push("CTRL");
        if (z.modifiers & Qt.AltModifier) m.push("ALT");
        if (z.modifiers & Qt.ShiftModifier) m.push("SHIFT");
        return m.concat([nazwa]).join(" + ");
    }

    // A key without SUPER, CTRL or ALT would take that key away from typing
    // in every program. Allowed alone: F keys and PrtSc.
    function bezpieczny(klawisze: string): bool {
        const r = rozbierz(klawisze);
        return (r.maska & (64 | 4 | 8)) !== 0 || /^(f([1-9]|1[0-2])|print)$/.test(r.klawisz);
    }

    // Qt key -> xkb keysym name as Hyprland accepts it in hl.bind.
    function nazwaKlawisza(k: int): string {
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k);
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k);
        if (k >= Qt.Key_F1 && k <= Qt.Key_F12) return "F" + (k - Qt.Key_F1 + 1);
        // With SHIFT held Qt reports the symbol on the digit key; Hyprland binds
        // the digit itself ("SUPER + SHIFT + 1"), like the desktop shortcuts.
        const cyfry = { [Qt.Key_Exclam]: "1", [Qt.Key_At]: "2", [Qt.Key_NumberSign]: "3",
                        [Qt.Key_Dollar]: "4", [Qt.Key_Percent]: "5", [Qt.Key_AsciiCircum]: "6",
                        [Qt.Key_Ampersand]: "7", [Qt.Key_Asterisk]: "8", [Qt.Key_ParenLeft]: "9",
                        [Qt.Key_ParenRight]: "0" };
        if (cyfry[k] !== undefined) return cyfry[k];
        const inne = {
            [Qt.Key_Left]: "left", [Qt.Key_Right]: "right", [Qt.Key_Up]: "up", [Qt.Key_Down]: "down",
            [Qt.Key_Space]: "space", [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "Return",
            [Qt.Key_Tab]: "Tab", [Qt.Key_Backspace]: "BackSpace", [Qt.Key_Delete]: "Delete",
            [Qt.Key_Insert]: "Insert", [Qt.Key_Home]: "Home", [Qt.Key_End]: "End",
            [Qt.Key_PageUp]: "Prior", [Qt.Key_PageDown]: "Next", [Qt.Key_Print]: "Print",
            [Qt.Key_Comma]: "comma", [Qt.Key_Period]: "period", [Qt.Key_Minus]: "minus",
            [Qt.Key_Equal]: "equal", [Qt.Key_Slash]: "slash", [Qt.Key_Backslash]: "backslash",
            [Qt.Key_Semicolon]: "semicolon", [Qt.Key_Apostrophe]: "apostrophe",
            [Qt.Key_BracketLeft]: "bracketleft", [Qt.Key_BracketRight]: "bracketright",
            [Qt.Key_QuoteLeft]: "grave"
        };
        return inne[k] ?? "";
    }

    FileView {
        id: plikSkrotow
        path: {
            const runtime = Quickshell.env("XDG_RUNTIME_DIR");
            const podpis = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE");
            return runtime && podpis ? runtime + "/hypr/" + podpis + "/skroty.json" : "";
        }
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { root.listaSkrotow = JSON.parse(text()); } catch (e) {}
        }
    }

    // After a live change hyprland.lua rewrites skroty.json itself; the
    // fixed list from "hyprctl binds" has to be read again.
    Timer {
        id: ponownyOdczytSkrotow
        interval: 300
        onTriggered: odczytSkrotow.running = true
    }

    // Key names as they appear on the keyboard, not as xkb calls
    // them - "XF86AudioRaiseVolume" and "mouse:272" mean nothing in the preview.
    readonly property var nazwyKlawiszy: ({
        "left": "←", "right": "→", "up": "↑", "down": "↓",
        "mouse:272": Tr.t("LMB", "LPM"), "mouse:273": Tr.t("RMB", "PPM"),
        "mouse_up": Tr.t("wheel ↑", "kółko ↑"), "mouse_down": Tr.t("wheel ↓", "kółko ↓"),
        "Print": "PrtSc",
        "XF86AudioRaiseVolume": Tr.t("volume up", "głośniej"), "XF86AudioLowerVolume": Tr.t("volume down", "ciszej"),
        "XF86AudioMute": Tr.t("mute", "wycisz"), "XF86AudioMicMute": Tr.t("microphone", "mikrofon"),
        "XF86AudioPlay": Tr.t("play", "odtwórz"), "XF86AudioPause": Tr.t("pause", "pauza"),
        "XF86AudioNext": Tr.t("next", "następny"), "XF86AudioPrev": Tr.t("previous", "poprzedni"),
        "XF86MonBrightnessUp": Tr.t("brighter", "jaśniej"), "XF86MonBrightnessDown": Tr.t("dimmer", "ciemniej")
    })

    Process {
        id: odczytSkrotow
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector { id: wyjscieSkrotow }
        onExited: {
            let lista;
            try { lista = JSON.parse(wyjscieSkrotow.text); } catch (e) { return; }
            // Binds of a submap (the capture's way out) are not active in the main map.
            const glowne = lista.filter(b => b.submap === "");
            root.wszystkieBindy = glowne;
            root.bindy = glowne.filter(b => b.description !== "");
        }
    }

    // ---------------------------------------------------------------
    //  SETTINGS FILE
    // ---------------------------------------------------------------
    FileView {
        id: plikUstawien
        path: root.sciezkaUstawien
        printErrors: false
        onLoaded: {
            const r = /^-- stan: (.*)$/m.exec(text());
            if (!r) { root.stan = root.domyslnyStan(); return; }
            try {
                root.stan = Object.assign(root.domyslnyStan(), JSON.parse(r[1]));
            } catch (e) {
                root.stan = root.domyslnyStan();
            }
        }
        onLoadFailed: root.stan = root.domyslnyStan()
    }

    Timer {
        id: zapis
        interval: 600
        onTriggered: plikUstawien.setText(root.wygeneruj())
    }

    function wygeneruj(): string {
        const s = stan;
        const w = [];
        w.push("-- stan: " + JSON.stringify(s));
        w.push("--");
        w.push("-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --");
        w.push("-- FILE MANAGED BY THE SHELL (Cogwheel -> Hyprland).");
        w.push("-- Manual edits will be overwritten by the next change in the Cogwheel.");
        w.push("-- \"Restore defaults\" deletes this file. It is loaded at the end of hyprland.lua.");
        w.push("-- The \"stan\" line above is the data this file is generated from.");
        w.push("-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --");
        w.push("");
        for (const klucz of Object.keys(s.opcje)) {
            const o = opcja(klucz);
            if (o) w.push("hl.config(" + tabelaLua(o.lua, s.opcje[klucz]) + ")");
        }
        if (s.tempo !== 1) w.push("ustawAnimacje(" + s.tempo + ")");
        if (s.czuloscTouchpada !== null && nazwaTouchpada !== "")
            w.push("hl.device({ name = " + literal(nazwaTouchpada) + ", sensitivity = " + s.czuloscTouchpada + " })");
        if (s.pietra !== 10 || s.nazwy.some(n => n) || !s.gesty)
            w.push("floors.ustaw({ pietra = " + s.pietra + ", nazwy = { "
                   + s.nazwy.map(n => literal(n || "")).join(", ") + " }, gesty = " + literal(s.gesty) + " })");
        if (s.monitor)
            w.push("hl.monitor({ output = " + literal(s.monitor.nazwa) + ", mode = " + literal(s.monitor.tryb)
                   + ", position = \"0x0\", scale = " + literal(String(s.monitor.skala)) + " })");
        if (s.drugiMonitor)
            w.push("hl.monitor({ output = " + literal(s.drugiMonitor.nazwa) + ", mode = \"preferred\", position = "
                   + literal(s.drugiMonitor.pozycja) + ", scale = \"auto\" })");
        const sk = s.skroty || { zmiany: {}, wlasne: [] };
        for (const id of Object.keys(sk.zmiany || {}))
            w.push("przypiszSkrot(" + literal(id) + ", " + literal(sk.zmiany[id]) + ")");
        for (const x of sk.wlasne || [])
            w.push("wlasnySkrot(" + literal(x.klawisze) + ", " + literal(x.komenda) + ", " + literal(x.nazwa) + ")");
        return w.join("\n") + "\n";
    }

    // ---------------- RESTORE DEFAULTS ----------------
    function przywrocDomyslne(): void {
        zapis.stop();
        przechwytuj(false);
        stan = domyslnyStan();
        // The path as a separate argument ($1), not pasted into the script:
        // JSON.stringify gives double quotes, inside which the shell still
        // expands $(...), backticks and $VAR from the directory name.
        Quickshell.execDetached(["sh", "-c", "rm -f -- \"$1\" && hyprctl reload",
                                 "sh", sciezkaUstawien]);
        ponownyOdczyt.restart();
    }

    // Reloading takes a moment - we read the values only after it.
    Timer {
        id: ponownyOdczyt
        interval: 1200
        onTriggered: root.odswiez()
    }
}
