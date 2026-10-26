pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Minimal copy of the bar's Theme singleton: live palette from colors.ini,
// so a window outside the bar (the network app, the lock screen) follows
// the wallpaper theming.
Singleton {
    id: root

    // the bar's state folder, where colors.ini and popup-scale live
    readonly property string stateDir: {
        const env = String(Quickshell.env("XDG_STATE_HOME") ?? "")
        const base = env !== "" ? env : String(Quickshell.env("HOME") ?? "") + "/.local/state"
        return base + "/sway-quickshell"
    }

    property color bg: "#0d1117"
    property color fg: "#c9d1d9"
    property color accent: "#58a6ff"
    property color green: "#8b949e"
    property color alert: "#f85149"
    property color disabled: "#484f58"

    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    // the bar's popup scale, read from the same file
    property real popupScale: 1.0

    FileView {
        path: root.stateDir + "/popup-scale"
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: root.popupScale = 1.0
        onLoaded: {
            const v = parseFloat(text())
            root.popupScale = isNaN(v) ? 1.0 : Math.min(Math.max(v, 0.8), 2.0)
        }
    }

    FileView {
        path: root.stateDir + "/colors.ini"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseIni(text())
    }

    function parseIni(t) {
        const map = {}
        for (const line of t.split("\n")) {
            const m = line.match(/^\s*([A-Za-z-]+)\s*=\s*(#[0-9a-fA-F]{3,8})/)
            if (m)
                map[m[1]] = m[2]
        }
        if (map["background"]) bg = map["background"]
        if (map["foreground"]) fg = map["foreground"]
        if (map["primary"]) accent = map["primary"]
        if (map["secondary"]) green = map["secondary"]
        if (map["alert"]) alert = map["alert"]
        if (map["disabled"]) disabled = map["disabled"]
    }
}
