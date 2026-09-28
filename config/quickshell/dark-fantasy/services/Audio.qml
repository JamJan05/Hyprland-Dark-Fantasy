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
//  AUDIO - A SINGLE SOURCE OF STATE FOR THE WHOLE SHELL.
//
//  Cogwheel, OSD and MediaPanel read
//  the volume FROM HERE. We must never allow a situation where each
//  of them runs its own "wpctl" or its own "pactl" - that is
//  exactly the kind of divergence that later shows up as
//  the OSD showing 40% and the panel 45%.
//
//  ---------------------------------------------------------------
//  WHY NATIVE PIPEWIRE AND NOT wpctl
//
//  The current bar calls "wpctl set-volume" on every wheel movement -
//  i.e. it spawns a process. Quickshell talks to PipeWire directly,
//  via Quickshell.Services.Pipewire, so:
//      - changing the volume is a property assignment,
//      - a change made ELSEWHERE (multimedia key,
//        pavucontrol, another application) arrives here by itself,
//        without polling.
//
//  ---------------------------------------------------------------
//  PwObjectTracker - AN EASY-TO-MISS REQUIREMENT
//
//  A PipeWire node is "bound" and reports live values only
//  when something tracks it. Without the PwObjectTracker below
//  sink.audio.volume simply does not update, and it looks
//  like a broken panel rather than one missing line.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // ---------------- OUTPUT (speakers) ----------------
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: sink !== null && sink.ready

    // Volume 0.0 - 1.0. PipeWire can go above 1.0
    // (software amplification), but the basic panel sticks to the
    // safe range - same as "-l 1" in the wpctl command
    // on the bar, which does not let the mouse wheel exceed 100%.
    readonly property real volume: sink?.audio?.volume ?? 0.0
    readonly property bool muted: sink?.audio?.muted ?? false

    // Device name for the panel subtitle. "description" tends to be
    // verbose ("Family 17h/19h HD Audio Controller Głośniki"),
    // so when a shorter common name exists, we take that.
    readonly property string sinkName: {
        if (sink === null) return "";
        if (sink.nickname !== "") return sink.nickname;
        if (sink.description !== "") return sink.description;
        return sink.name;
    }

    // ---------------- INPUT (microphone) ----------------
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool sourceReady: source !== null && source.ready

    readonly property real micVolume: source?.audio?.volume ?? 0.0
    readonly property bool micMuted: source?.audio?.muted ?? false

    readonly property string sourceName: {
        if (source === null) return "";
        if (source.nickname !== "") return source.nickname;
        if (source.description !== "") return source.description;
        return source.name;
    }

    // ================================================================
    //  APPLICATION STREAMS (per-application audio)
    //
    //  No "pactl -f json list sink-inputs" needed: PipeWire exposes the
    //  streams natively. A playback stream is a node that is Audio, Sink and
    //  Stream at the same time - in Quickshell the PwNodeType.AudioOutStream
    //  flag. wpctl cannot set the volume of individual streams, but PipeWire
    //  can: every stream has its own audio.volume and audio.muted, exactly
    //  like a device.
    // ================================================================
    readonly property var streams: {
        const lista = [];
        for (const n of Pipewire.nodes.values) {
            // isSink on a stream means "receives sound", i.e. it
            // is playback, not recording. Application microphone
            // streams (isSource) are deliberately skipped -
            // the panel shows what can be heard.
            if (!n.isStream) continue;
            if (!n.isSink) continue;
            if (n.audio === null) continue;
            lista.push(n);
        }
        return lista;
    }

    readonly property bool anyStream: streams.length > 0

    // Application name to display. PipeWire provides it in the
    // node properties; several are tried in order, because not every
    // program fills in all fields.
    function streamName(node): string {
        if (node === null) return "";
        const w = node.properties;
        if (w) {
            if (w["application.name"]) return w["application.name"];
            if (w["node.description"]) return w["node.description"];
        }
        if (node.description !== "") return node.description;
        return node.name;
    }

    // What this application is currently playing - track title, file name, browser
    // tab. Can be empty, and then the row shows only the program name.
    function streamTitle(node): string {
        if (node === null) return "";
        const w = node.properties;
        if (w && w["media.name"]) return w["media.name"];
        return "";
    }

    function setStreamVolume(node, wartosc: real) {
        if (node === null || node.audio === null) return;
        node.audio.volume = Math.max(0.0, Math.min(1.0, wartosc));
    }

    function toggleStreamMute(node) {
        if (node === null || node.audio === null) return;
        node.audio.muted = !node.audio.muted;
    }

    // ---------------- WRITE ----------------
    // All changes go through these four functions, so that nowhere
    // else do you have to remember to check whether the node
    // exists at all. At session start, before WirePlumber
    // sets the default device, "sink" can be empty for a moment.

    function setVolume(wartosc: real) {
        if (sink?.audio === null || sink?.audio === undefined) return;
        sink.audio.volume = Math.max(0.0, Math.min(1.0, wartosc));
    }

    function toggleMute() {
        if (sink?.audio === null || sink?.audio === undefined) return;
        sink.audio.muted = !sink.audio.muted;
    }

    function setMicVolume(wartosc: real) {
        if (source?.audio === null || source?.audio === undefined) return;
        source.audio.volume = Math.max(0.0, Math.min(1.0, wartosc));
    }

    function toggleMicMute() {
        if (source?.audio === null || source?.audio === undefined) return;
        source.audio.muted = !source.audio.muted;
    }

    // ---------------- TRACKING ----------------
    // Without this both nodes are "unbound" and their audio.* fields stay
    // frozen. This is NOT an optimization that can be skipped.
    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.streams)
    }
}
