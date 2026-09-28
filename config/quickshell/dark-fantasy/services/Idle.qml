pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT.
// Quickshell's scanner stops reading the header at the first line
// containing "{", without stripping comments first. Details
// in services/Brightness.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  IDLE INHIBITOR - ONE OWNER, TWO VIEWS.
//
//  Keeps hypridle from doing what it does after inactivity:
//      300 s  - turns the screen off (DPMS off)
//      600 s  - locks the session
//      1800 s - suspends the computer
//
//  ---------------------------------------------------------------
//  WHY NOT "SYNCHRONIZATION" WITH WAYBAR
//
//  Waybar's built-in "idle_inhibitor" module holds the inhibitor ITSELF, via
//  the idle-inhibit protocol. It can be neither read nor set
//  from outside - it is internal to the bar.
//
//  If the panel held a second inhibitor next to that one, there would be TWO
//  independent ones: you turn it off in the panel, and the screen still does not turn off, because the bar
//  holds its own. Two states that cannot be reconciled.
//
//  That is why only Quickshell holds the inhibitor. The toggle is
//  in the Cogwheel (System -> Behavior), and scripts are left with
//  "qs ipc call idle toggle".
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQml
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // The only inhibitor state in the whole system. The inhibitor itself is set up by
    // the IdleInhibitor element in hud/Hud.qml - it needs a window, and a singleton
    // does not have one.
    property bool inhibited: false

    function toggle() {
        inhibited = !inhibited;
    }
}
