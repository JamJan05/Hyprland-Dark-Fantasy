pragma Singleton

// THE PRAGMA MUST COME BEFORE THE COMMENT, NOT AFTER IT.
// Quickshell's scanner stops reading the header at the first line
// containing "{", without stripping comments first - a brace
// in a comment would disable singleton registration. Details
// in services/Brightness.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  PLAYER - A SINGLE SOURCE OF TRUTH ABOUT WHAT IS PLAYING.
//
//  MediaPanel and future bar elements read the state FROM HERE, just
//  as the volume comes from Audio.qml. There is no playerctl here and nothing
//  is polled - Quickshell.Services.Mpris listens on D-Bus
//  and reports changes by itself.
//
//  ---------------------------------------------------------------
//  WHICH PLAYER TO SHOW
//
//  Spotify is not the only one. In practice several run in the background at once: Spotify,
//  a YouTube tab in Firefox and mpv. Selection policy, in order:
//
//    1. the one that is CURRENTLY PLAYING;
//    2. if several are playing - the one that started playing last;
//    3. if none is playing - the last one that played (as long as it still
//       exists), so that the panel does not jump to a random program
//       the moment you pause;
//    4. any paused one;
//    5. whichever comes first.
//
//  Points 2 and 3 require remembering who played last. This is done by
//  the Instantiator below: it attaches one observer to each
//  player and records its identifier at the moment it
//  starts playing. Without this there would be nothing to determine "most recently active"
//  with - the list from Mpris.players has no defined order.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import QtQml
import QtQml.Models
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // D-Bus names that we do NOT treat as a player.
    //
    // playerctld is a proxy: it plays nothing itself, it only forwards
    // commands to the "most recently active" program. Yet it registers with MPRIS
    // as a regular player, so without this filter the panel would show
    // an empty card with no title and no cover, and the log would fill up, on
    // every refresh, with:
    //     QDBusError("com.github.altdesktop.playerctld.NoActivePlayer")
    //
    // The bar uses playerctld and has every right to - Waybar's mpris module
    // hooks into it for exactly that purpose. We read the real
    // players directly, so the middleman is just noise here.
    readonly property list<string> pomijane: ["playerctld"]

    readonly property var players: {
        const lista = [];
        for (const p of Mpris.players.values) {
            let pomin = false;
            for (const nazwa of pomijane) {
                if (p.dbusName.indexOf(nazwa) !== -1) { pomin = true; break; }
            }
            if (!pomin) lista.push(p);
        }
        return lista;
    }

    readonly property bool any: players.length > 0

    // uniqueId of the player that started playing most recently.
    // 0 means "none yet".
    property int ostatnioGral: 0

    readonly property MprisPlayer active: {
        const lista = players;
        if (lista.length === 0) return null;

        // 1 and 2: playing now. With several playing, the one
        // that started last wins.
        let pierwszyGrajacy = null;
        for (const p of lista) {
            if (p.playbackState !== MprisPlaybackState.Playing) continue;
            if (p.uniqueId === ostatnioGral) return p;
            if (pierwszyGrajacy === null) pierwszyGrajacy = p;
        }
        if (pierwszyGrajacy !== null) return pierwszyGrajacy;

        // 3: nobody is playing - we stay with the one that played last.
        // Thanks to this, pausing does not switch the panel to another program.
        for (const p of lista) {
            if (p.uniqueId === ostatnioGral) return p;
        }

        // 4: any paused one.
        for (const p of lista) {
            if (p.playbackState === MprisPlaybackState.Paused) return p;
        }

        // 5: anything.
        return lista[0];
    }

    readonly property bool playing:
        active !== null && active.playbackState === MprisPlaybackState.Playing

    // Program name for the panel footer. "identity" is the nice name
    // given by the player itself ("Spotify", "Mozilla Firefox"),
    // much better than the D-Bus address, to which browsers append
    // the process number (org.mpris.MediaPlayer2.chromium.instance1234).
    readonly property string name: {
        if (active === null) return "";
        if (active.identity !== "") return active.identity;
        return active.dbusName;
    }

    // ---------------------------------------------------------------
    //  LOOP AND SHUFFLE
    //
    //  MPRIS reports both as optional: a player that has no playlist
    //  (a browser tab, mpv with one file) reports loopSupported /
    //  shuffleSupported false, and canControl false means the whole
    //  player is read-only (e.g. a stream). The panel greys the glyph
    //  out in those cases instead of sending a write that would only
    //  produce a D-Bus error in the log.
    // ---------------------------------------------------------------
    readonly property bool loopSupported:
        active !== null && active.canControl && active.loopSupported
    readonly property int loopState: active?.loopState ?? MprisLoopState.None

    readonly property bool shuffleSupported:
        active !== null && active.canControl && active.shuffleSupported
    readonly property bool shuffle: active?.shuffle ?? false

    // ---------------------------------------------------------------
    //  WHO STARTED PLAYING
    // ---------------------------------------------------------------
    Instantiator {
        // We take the model from Mpris, not from the filtered list: Instantiator
        // needs a model that reports changes by itself, and a plain JS
        // array would rebuild all observers on every state
        // change. Proxies are filtered out in the observer itself.
        model: Mpris.players

        delegate: Connections {
            required property MprisPlayer modelData

            target: modelData

            function onPlaybackStateChanged() {
                if (modelData.playbackState !== MprisPlaybackState.Playing) return;
                for (const nazwa of root.pomijane) {
                    if (modelData.dbusName.indexOf(nazwa) !== -1) return;
                }
                root.ostatnioGral = modelData.uniqueId;
            }
        }
    }

    // ---------------------------------------------------------------
    //  CONTROLS
    //
    //  Every method checks the corresponding "can*". MPRIS lets
    //  a player report that it cannot do something, and calling it
    //  anyway ends at best in silence, at worst in a
    //  warning in the log on every click.
    // ---------------------------------------------------------------
    function toggle() {
        if (active !== null && active.canTogglePlaying) active.togglePlaying();
    }

    function next() {
        if (active !== null && active.canGoNext) active.next();
    }

    function previous() {
        if (active !== null && active.canGoPrevious) active.previous();
    }

    // Seek to the given second. Not every player
    // can do this - browsers often report canSeek false.
    function seekTo(sekunda: real) {
        if (active === null || !active.canSeek || !active.positionSupported) return;
        active.position = Math.max(0, Math.min(active.length, sekunda));
    }

    // Raises the player window. Not all players support this.
    function raise() {
        if (active !== null && active.canRaise) active.raise();
    }

    // Off -> this track -> whole playlist -> off. "This track" comes
    // first, because that is the one you reach for while listening.
    function cycleLoop() {
        if (!loopSupported) return;
        const s = active.loopState;
        active.loopState = s === MprisLoopState.None  ? MprisLoopState.Track
                         : s === MprisLoopState.Track ? MprisLoopState.Playlist
                         :                              MprisLoopState.None;
    }

    function toggleShuffle() {
        if (!shuffleSupported) return;
        active.shuffle = !active.shuffle;
    }
}
