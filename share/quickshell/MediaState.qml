pragma Singleton
import QtQuick
import QtQml
import Quickshell
import Quickshell.Services.Mpris

// Now-playing state shared by every output's Media pill and popup: which
// player shows (the playing one wins; the popup can pin one, dropped when
// it exits), players middle-click dismissed until they change track or
// play after a pause, and the position, ticked while playing (MPRIS doesn't
// push it).
Singleton {
    id: root

    property var manual: null
    // bus name -> {title, paused}: the track and whether it was paused
    // when dismissed
    property var dismissed: ({})
    property int dismissals: 0
    function dismiss(p) {
        dismissed[p.dbusName] = { title: p.trackTitle ?? "",
                                  paused: p.playbackState !== MprisPlaybackState.Playing }
        dismissals++
    }
    function undismiss(p) {
        if (!dismissed[p.dbusName])
            return
        delete dismissed[p.dbusName]
        dismissals++
    }
    readonly property var player: {
        void dismissals
        const ps = Mpris.players.values
        if (manual && ps.indexOf(manual) >= 0)
            return manual
        for (let i = 0; i < ps.length; i++)
            if (ps[i].playbackState === MprisPlaybackState.Playing)
                return ps[i]
        for (let i = 0; i < ps.length; i++)
            if (!dismissed[ps[i].dbusName])
                return ps[i]
        return null
    }
    readonly property bool playing: player !== null
        && player.playbackState === MprisPlaybackState.Playing
    // shown on the bars unless dismissed or stopped
    readonly property bool shown: {
        void dismissals
        return player !== null && !dismissed[player.dbusName]
            && player.playbackState !== MprisPlaybackState.Stopped
    }

    // MPRIS reports artists as an array, but some players hand over a
    // plain string
    readonly property string artistText: {
        const a = player?.trackArtists
        if (!a) return ""
        return Array.isArray(a) ? a.join(", ") : String(a)
    }

    property real pos: 0
    readonly property real len: player?.length ?? 0
    readonly property bool timed: len > 0 && isFinite(len)

    Timer {
        running: root.shown && root.playing
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.pos = root.player?.position ?? 0
    }
    // re-read at once on a track change or a seek while paused
    Connections {
        target: root.player
        function onTrackTitleChanged() { root.pos = root.player?.position ?? 0 }
        function onPositionChanged() { root.pos = root.player?.position ?? 0 }
    }
    // a dismissed player comes back on a new track, or on play after a
    // pause; players re-announce "playing" now and then, which doesn't count.
    // Every player is watched: a dismissed one may not be the one shown.
    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property var modelData
            target: modelData
            function onTrackTitleChanged() {
                const d = root.dismissed[modelData.dbusName]
                if (d && (modelData.trackTitle ?? "") !== d.title)
                    root.undismiss(modelData)
            }
            function onPlaybackStateChanged() {
                const d = root.dismissed[modelData.dbusName]
                if (!d)
                    return
                if (modelData.playbackState !== MprisPlaybackState.Playing)
                    d.paused = true
                else if (d.paused)
                    root.undismiss(modelData)
            }
        }
    }

    function fmt(s) {
        s = Math.max(0, Math.round(s))
        const m = Math.floor(s / 60), r = s % 60
        return (m >= 60 ? Math.floor(m / 60) + ":" + String(m % 60).padStart(2, "0")
                        : m) + ":" + String(r).padStart(2, "0")
    }
}
