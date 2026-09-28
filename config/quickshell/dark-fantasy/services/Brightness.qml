pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT.
//
// Quickshell's scanner (src/core/scan.cpp) reads the file header line by
// line and stops at the FIRST line containing "{" - without stripping
// comments first. A brace in a descriptive comment therefore closes the
// header before the scanner reaches "pragma Singleton", and the file gets
// registered as a regular type instead of a singleton. This shows up as
// the error "Property 'x' of object Y is not a function" at the point of use,
// not in this file - which makes it hard to link the symptom to the cause.
//
// Keeping the pragma on the first line makes the file immune to comment contents.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  SCREEN BRIGHTNESS - A SINGLE SOURCE OF STATE FOR THE WHOLE SHELL.
//
//  ---------------------------------------------------------------
//  READING IS REACTIVE, WITHOUT A SINGLE POLL
//
//  A common belief is that "sysfs does not emit events that
//  QFileSystemWatcher would catch". For the backlight it is false, verified
//  experimentally: FileView with watchChanges on
//  /sys/class/backlight/<dev>/brightness detects EVERY change - including one
//  made with the hardware key through brightnessctl called from hyprland.lua.
//
//  Test: three brightnessctl changes, three FileView events
//  (64764 -> 58288 -> 45335 -> 64764). Thanks to this:
//    - there is no Timer or polling here at all,
//    - the panel does not have to tell the service when to look,
//    - the OSD gets notified at the moment of the change, not up to a second
//      later,
//    - the XF86MonBrightness* shortcuts in hyprland.lua stay untouched
//      and still simply call brightnessctl.
//
//  ---------------------------------------------------------------
//  A PROCESS IS NEEDED FOR ONLY TWO THINGS
//
//  1. Finding the device. The /sys/class/backlight directory cannot be
//     listed from QML, and "brightnessctl -lm" is already on the system anyway.
//     We do it ONCE, at shell startup.
//  2. Writing. The "brightness" file in sysfs belongs to root; brightnessctl
//     has a udev rule, and that is what allows writing without elevating privileges.
//     Reading goes straight from sysfs - we have permissions for that.
//
//  ---------------------------------------------------------------
//  THE DEVICE IS NOT HARDCODED
//
//  No device name in the configuration: a fixed "amdgpu_bl0" would tie it to
//  a single laptop. Waybar's "backlight" module has no "device" key for the
//  same reason.
//
//  The class filter matters. "brightnessctl -lm" on this machine
//  prints fourteen devices, thirteen of which are LEDs:
//      amdgpu_bl0,backlight,64764,100%,64764   <- we want this
//      tpacpi::kbd_backlight,leds,2,100%,2     <- not this
//  Without the filter the panel could end up on the keyboard backlight.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQml
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Name of the detected device, e.g. "amdgpu_bl0". Empty until
    // the first read returns.
    readonly property string device: urzadzenie
    readonly property bool ready: urzadzenie !== "" && maks > 0

    // Brightness 0.0 - 1.0.
    readonly property real value: maks > 0 ? biezaca / maks : 0.0

    // Lower bound of the slider. 5% - below this value the screen becomes
    // unreadable, and at zero it looks switched off and the user does not
    // know they dimmed it themselves. The same bound the brightness
    // slider on the bar had ("min": 5 in config.jsonc).
    readonly property real minimum: 0.05

    property string urzadzenie: ""
    property int biezaca: 0
    property int maks: 0

    readonly property string katalog:
        urzadzenie === "" ? "" : "/sys/class/backlight/" + urzadzenie

    // ---------------------------------------------------------------
    //  DEVICE DETECTION - one process, once at startup
    // ---------------------------------------------------------------
    // "brightnessctl -lm" row format:
    //     name,class,current,percent%,maximum
    function parsujListe(tekst: string) {
        for (const wiersz of tekst.trim().split("\n")) {
            const p = wiersz.split(",");
            if (p.length < 5) continue;
            if (p[1] !== "backlight") continue;

            // The first backlight-class device wins - the same rule
            // Waybar's backlight module and pamiec-ustawien follow.
            root.urzadzenie = p[0];
            return;
        }
    }

    Process {
        id: wykryj
        running: true
        command: ["brightnessctl", "-lm"]
        stdout: StdioCollector { id: wyjscie }
        onExited: function (kod) {
            if (kod === 0) root.parsujListe(wyjscie.text);
        }
    }

    // ---------------------------------------------------------------
    //  READING FROM SYSFS
    // ---------------------------------------------------------------
    // The maximum is constant for a device - we read it once, without watching.
    FileView {
        path: root.katalog === "" ? "" : root.katalog + "/max_brightness"
        onLoaded: {
            const n = parseInt(text().trim(), 10);
            if (!isNaN(n)) root.maks = n;
        }
    }

    // Current value - watched. This is what makes the whole service reactive.
    FileView {
        path: root.katalog === "" ? "" : root.katalog + "/brightness"
        watchChanges: true

        // At the moment of the event FileView still has the OLD content - we get
        // the new one only after reloading, in onLoaded. Reading
        // text() directly in onFileChanged would give the value from before the change.
        // It shows plainly in the test log: "ZMIANA: 64764" right before
        // "start: 58288".
        onFileChanged: reload()

        onLoaded: {
            const n = parseInt(text().trim(), 10);
            if (!isNaN(n)) root.biezaca = n;
        }
    }

    // ---------------------------------------------------------------
    //  WRITING
    // ---------------------------------------------------------------
    function setValue(wartosc: real) {
        if (!ready) return;

        const docelowa = Math.max(minimum, Math.min(1.0, wartosc));

        // We predict the result right away, without waiting for the process or
        // the sysfs event. Without this the slider handle would jump back to the old
        // position for those few dozen milliseconds before brightnessctl
        // manages to run - the slider would look like it was stuttering.
        biezaca = Math.round(docelowa * maks);

        // "-n2" makes sure we never go below the value 2 -
        // the same flag as in the keyboard shortcuts in hyprland.lua.
        zapisz.command = [
            "brightnessctl", "-n2", "-d", urzadzenie,
            "set", Math.round(docelowa * 100) + "%"
        ];
        zapisz.running = true;
    }

    Process {
        id: zapisz
        // We do not read the output - the real value will come
        // back anyway as a sysfs event.
    }
}
