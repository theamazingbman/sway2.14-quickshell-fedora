pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Focus timer. One copy for the whole shell: every bar's command pill
// shows it, and the end-of-timer chime and notification fire once,
// however many outputs there are. Duration edits only while idle
// (− / + on the Focus timer tile, 5 min steps, 5–90).
Singleton {
    id: root

    property int minutes: 25
    readonly property int total: minutes * 60
    property double endMs: 0
    property int remaining: 0
    property bool done: false    // time's up, not yet acknowledged
    readonly property bool running: endMs > 0

    // end-timestamp + minutes in a plain state file so a running timer
    // (and the duration preference) survives bar restarts; watched, so
    // `echo "0 25" > ~/.local/state/mango/pomodoro` stops it from a shell
    function persist() { Theme.writeState("pomodoro", Math.round(endMs) + " " + minutes) }

    FileView {
        path: Theme.stateDir + "/pomodoro"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const parts = text().trim().split(/\s+/)
            const end = parseFloat(parts[0]) || 0
            const mins = parseInt(parts[1]) || 0
            if (mins >= 5 && mins <= 90)
                root.minutes = mins
            if (end > Date.now()) {
                root.endMs = end
                root.remaining = Math.round((end - Date.now()) / 1000)
            } else if (end === 0) {
                root.endMs = 0
            }
            // end in the past: expired while the bar was down — stay idle
        }
    }

    function fmt(s) {
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }
    function toggle() {
        done = false
        if (running) {
            endMs = 0
        } else {
            endMs = Date.now() + total * 1000
            remaining = total
        }
        persist()
    }
    function nudge(dir) {
        if (running) return
        minutes = Math.min(90, Math.max(5, minutes + dir * 5))
        persist()
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: {
            root.remaining = Math.max(0, Math.round((root.endMs - Date.now()) / 1000))
            if (root.remaining <= 0) {
                root.endMs = 0
                root.done = true
                root.persist()
                // chime plays regardless of DND — it's an alarm; the
                // notification lands in dunst history if DND holds it
                Quickshell.execDetached(["paplay", "--volume=40000",
                    "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"])
                Quickshell.execDetached(["notify-send", "-u", "critical",
                    "Pomodoro", "Time's up — take a break"])
            }
        }
    }
}
