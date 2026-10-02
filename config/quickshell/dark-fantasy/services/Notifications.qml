pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT.
// Quickshell's scanner stops reading the header at the first line
// containing "{", without stripping comments first. Details
// in services/Brightness.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  NOTIFICATIONS - THE SHELL IS THE DAEMON.
//
//  Quickshell registers on D-Bus under the name
//  org.freedesktop.Notifications, and from then on all
//  notifications in the system go through here.
//
//  ---------------------------------------------------------------
//  TWO DAEMONS CANNOT EXIST AT THE SAME TIME
//
//  The D-Bus name is held by exactly one process. If SwayNC starts
//  first, our server will not get it and will silently never see a single
//  notification. That is why, together with this file:
//    - swaync is removed from autostart in hyprland.lua,
//    - the .service file in local/share/dbus-1 points to the shell,
//      not to swaync.
//
//  The swaync package STAYS installed. Going back means restoring those
//  two places - or simply "git checkout main".
//
//  ---------------------------------------------------------------
//  WHAT HAD TO BE WRITTEN BY HAND
//
//  Quickshell provides the server, popups, actions, images and inline
//  replies. It does NOT provide history, grouping or counting - and that is
//  the whole difference in effort compared to SwayNC, which had it built in.
//  The history lives further down in this file.
//
//  ---------------------------------------------------------------
//  HISTORY LIVES IN MEMORY
//
//  Same as in SwayNC: notifications do not survive logging out.
//  We deliberately do not save them to disk - notifications can be private
//  (message contents, login codes), and a file in the home directory
//  would outlive the session and end up in backups.
//
//  "keepOnReload", on the other hand, makes them survive a reload of the shell
//  itself - without it every QML change would wipe the history.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications as QSN

Singleton {
    id: root

    // ---------------- HISTORY ----------------
    // Newest at the top. We keep our own list rather than
    // server.trackedNotifications, because we need ordering
    // and the ability to remove an entry without closing the notification
    // on the application side.
    property var history: []

    readonly property int count: history.length

    // History is capped. Each entry keeps the notification tracked (image
    // data included) until it is dismissed, so in a long session without
    // clearing the list memory only grew. The oldest ones beyond the limit
    // are closed as expired.
    readonly property int limitHistorii: 100

    // ---------------- POPUPS ----------------
    // The subset of the history currently shown on screen.
    property var popups: []

    // ---------------- DO NOT DISTURB ----------------
    // Kept in UstawieniaPowloki (powloka.json), so it survives a shell
    // restart, a logout and a reboot.
    readonly property bool dnd: UstawieniaPowloki.dnd

    // Also when the saved "on" arrives only after powloka.json has loaded:
    // a notification that came in before that must not stay up as a popup.
    onDndChanged: if (dnd) ustawPopupy([])

    // How many seconds a popup stays up. The same values that
    // config/swaync/config.json had - so that switching the daemon does not
    // also change the behavior you are used to:
    //     timeout          8
    //     timeout-low      4
    //     timeout-critical 0  (does not disappear on its own)
    readonly property int czasZwykly: 8
    readonly property int czasNiski: 4

    function czasDlaPowiadomienia(n): int {
        if (n === null) return czasZwykly;
        if (n.urgency === QSN.NotificationUrgency.Critical) return 0;

        // An application can provide its own timeout. A negative value means
        // "decide yourself", zero - "do not close automatically".
        if (n.expireTimeout > 0) return Math.round(n.expireTimeout);
        if (n.expireTimeout === 0) return 0;

        return n.urgency === QSN.NotificationUrgency.Low ? czasNiski : czasZwykly;
    }

    // ---------------------------------------------------------------
    //  SERVER
    // ---------------------------------------------------------------
    QSN.NotificationServer {
        id: serwer

        // History survives a shell reload.
        keepOnReload: true

        // What we advertise to applications. We declare only what the panel
        // can actually display - promising something we cannot
        // do ends in notifications that look broken.
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        // No image and no inline reply: NotificationCard renders neither.
        // Advertising inline reply made Quickshell remove the app's own
        // "Reply" action, so messengers lost replying altogether.
        imageSupported: false
        inlineReplySupported: false
        persistenceSupported: true

        onNotification: function (n) {
            // Without this Quickshell drops the notification right after
            // it arrives. This is the one line without which
            // everything looks like it works, yet nothing shows up.
            n.tracked = true;

            // "transient" means: show it, but do not keep it in history.
            // Used e.g. by the volume indicators of other shells.
            if (!n.transient) {
                const nowa = [n].concat(root.history);
                root.history = nowa.slice(0, root.limitHistorii);
                for (const stara of nowa.slice(root.limitHistorii)) {
                    if (root.popups.indexOf(stara) === -1) stara.expire();
                }
            }

            // keepOnReload: after a shell reload the server sends every
            // tracked notification again, marked lastGeneration. They go
            // back into history, but must not pop up a second time.
            // A transient one is in neither list then, so it is closed.
            if (n.lastGeneration) {
                if (n.transient) n.expire();
                return;
            }

            // With "do not disturb" on, the notification goes
            // into history but does not pop up on screen. Critical ones
            // get through regardless - that is the whole point of this urgency
            // level.
            const krytyczne = n.urgency === QSN.NotificationUrgency.Critical;
            if (!root.dnd || krytyczne) {
                root.popups = root.popups.concat([n]);
            } else if (n.transient) {
                // Not shown and not kept: nothing would ever release it.
                n.expire();
            }
        }
    }

    // No signal to the bar when the counter changes: the pending count is
    // shown by the corner of the Tidings tile, which binds to "count" directly.

    // ---------------------------------------------------------------
    //  ACTIONS
    // ---------------------------------------------------------------

    // Dismiss all popups at once. Called when the center opens:
    // popups sit on the Overlay layer and the center on Top, so they would be drawn
    // ABOVE it and cover the first entries of the list. Besides, showing
    // the same notification twice at once makes no sense - the center
    // contains them all.
    function hideAllPopups() {
        ustawPopupy([]);
    }

    // Hide a popup. The notification stays in history.
    function hidePopup(n) {
        ustawPopupy(root.popups.filter(function (x) { return x !== n; }));
    }

    // Every change of the popup list goes through here. A notification
    // that is not in history - a transient one, or one pushed out by the
    // history limit while its popup was up - has nothing referring to it
    // once its popup is gone, so it is closed as expired. Before, it stayed
    // tracked for good, invisible, and "clear all" could not reach it.
    function ustawPopupy(nowe) {
        const stare = root.popups;
        root.popups = nowe;
        for (const n of stare) {
            if (n !== null && nowe.indexOf(n) === -1 && root.history.indexOf(n) === -1)
                n.expire();
        }
    }

    // Remove from history and close on the application side.
    function dismiss(n) {
        // Not through hidePopup: that would expire a transient one first,
        // and the dismiss below would then hit a closed notification.
        root.popups = root.popups.filter(function (x) { return x !== n; });
        root.history = root.history.filter(function (x) { return x !== n; });
        if (n !== null) n.dismiss();
    }

    function clearAll() {
        const kopia = root.history;
        // Popups that are not in history (transient, or pushed out by the
        // limit) are expired - the rest are dismissed with the history below.
        const pozaHistoria = root.popups.filter(n => n !== null && kopia.indexOf(n) === -1);
        root.history = [];
        root.popups = [];
        for (const n of pozaHistoria) n.expire();
        for (const n of kopia) {
            if (n !== null) n.dismiss();
        }
    }

    function invoke(akcja, n) {
        if (akcja === null) return;
        akcja.invoke();
        // A "resident" notification stays after an action is clicked -
        // that is how e.g. players with playback control buttons behave.
        if (n !== null && !n.resident) dismiss(n);
    }

    function reply(n, tekst: string) {
        if (n === null || !n.hasInlineReply || tekst === "") return;
        n.sendInlineReply(tekst);
        dismiss(n);
    }

    function toggleDnd() {
        const wlacz = !dnd;
        // Enabling DND clears whatever is currently up (onDndChanged above) -
        // otherwise you would have to wait for them to disappear on their own.
        UstawieniaPowloki.ustawDnd(wlacz);
    }

    // Cleans the list of notifications closed by the application itself.
    // Quickshell removes them from its model, and our copy would be left
    // with dangling pointers.
    Connections {
        target: serwer.trackedNotifications

        function onValuesChanged() {
            const zywe = serwer.trackedNotifications.values;
            root.history = root.history.filter(function (n) {
                return zywe.indexOf(n) !== -1;
            });
            root.popups = root.popups.filter(function (n) {
                return zywe.indexOf(n) !== -1;
            });
        }
    }
}
