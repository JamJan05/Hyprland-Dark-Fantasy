pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT - see Brightness.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  SESSION - lock, suspend, log out, reboot, power off.
//
//  A single place with the commands that end or suspend work.
//  They are called by the Bonfire tile (kafle/Ognisko.qml). The commands are the same as
//  in config/hypr/hypridle.conf:
//
//      lock        pidof hyprlock || hyprlock   - guard against a second
//                  lock instance (see hyprland.lua, SUPER+L)
//      suspend     loginctl suspend
//      log out     hyprshutdown, or hl.dsp.exit() without it - the same
//                  as SUPER+M in hyprland.lua
//      reboot      loginctl reboot
//      power off   loginctl poweroff
//
//  The system runs on OpenRC + elogind, hence loginctl and not systemctl.
//  On systemd the last three commands have to be replaced.
//
//  No hibernation: this laptop has no swap partition the size of RAM, so it
//  would not work anyway.
//
//  execDetached, not Process: the command has to outlive the shell. Logging out
//  closes Hyprland together with Quickshell - a child process would die
//  halfway through the job.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import Quickshell

Singleton {
    function sh(polecenie: string): void {
        Quickshell.execDetached(["sh", "-c", polecenie]);
    }

    function zablokuj(): void {
        sh("pidof hyprlock || hyprlock");
    }

    function uspij(): void {
        sh("loginctl suspend");
    }

    function wyloguj(): void {
        // A temporary pairing trust must not outlive the session - taken back,
        // and confirmed by BlueZ, before the teardown (PamiecBluetooth.przedWyjsciem).
        sh(PamiecBluetooth.przedWyjsciem() + "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'");
    }

    function uruchomPonownie(): void {
        // See wyloguj().
        sh(PamiecBluetooth.przedWyjsciem() + "loginctl reboot");
    }

    function wylacz(): void {
        // See wyloguj().
        sh(PamiecBluetooth.przedWyjsciem() + "loginctl poweroff");
    }
}
