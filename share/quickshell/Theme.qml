pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live palette from the state folder's colors.ini, which
// scripts/wallpaper-theme rewrites on every wallpaper change; watching it
// re-colors the bar with no restart. Defaults are github_dark placeholders.
// The file's palette is small, so the semantic names below collapse onto
// it: red→alert, yellow→primary, blue/green/cyan/magenta→secondary.
Singleton {
    id: root

    // FileView watching a file, re-read whenever it changes
    component StateFile: FileView { watchChanges: true; onFileChanged: reload() }

    // The setup's own files (this bar, the scripts, templates) live in
    // the share folder, the parent of the running quickshell dir — derived,
    // never hardcoded. Replaced wholesale on update.
    readonly property string shareDir: {
        let sd = String(Quickshell.shellDir ?? "")
        if (sd.startsWith("file://"))
            sd = sd.slice(7)
        return sd.substring(0, sd.lastIndexOf("/"))
    }

    // The user's folder: config.conf, keybinds.conf, local.conf and the
    // wallpapers they add. Never replaced by an update.
    readonly property string confDir: {
        const env = String(Quickshell.env("XDG_CONFIG_HOME") ?? "")
        const base = env !== "" ? env : String(Quickshell.env("HOME") ?? "") + "/.config"
        return base + "/sway"
    }

    // Settings the bar keeps between restarts (bar height, weather
    // location, kept monitor layouts...) live outside the config folder,
    // in XDG_STATE_HOME, so reinstalling or updating the config never
    // loses them. scripts/bar creates the folder.
    readonly property string stateDir: {
        const env = String(Quickshell.env("XDG_STATE_HOME") ?? "")
        const base = env !== "" ? env : String(Quickshell.env("HOME") ?? "") + "/.local/state"
        return base + "/sway-quickshell"
    }

    // bar height (px) and element scale, persisted to plain files (like
    // weather-location) so the tweaks sliders survive restarts
    property int barHeight: 42
    property real barUserScale: 1.0

    // both state files attempted (present or not); bars gate their first
    // map on this to appear once, at final size. The timer failsafe
    // guarantees the bar always maps.
    property int _barStateLoads: 0
    readonly property bool barStateReady: _barStateLoads >= 2
    Timer {
        running: !root.barStateReady
        interval: 1000
        onTriggered: root._barStateLoads = 2
    }

    property color bg: "#0d1117"
    property color altbg: "#161b22"
    property color fg: "#c9d1d9"
    property color border: "#30363d"
    property color primary: "#58a6ff"
    property color secondary: "#8b949e"
    property color alert: "#f85149"
    property color disabled: "#484f58"

    readonly property color accent: primary
    readonly property color selbg: primary
    readonly property color selfg: bg
    readonly property color red: alert
    readonly property color yellow: primary
    readonly property color blue: secondary
    readonly property color green: secondary
    readonly property color cyan: secondary
    readonly property color magenta: secondary

    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    // Base scale from the outputs' logical short side: 1.0 at 1080p, 1.33
    // at 1440p, 2.0 at unscaled 4K. A mango output scale shrinks the
    // logical size, so nothing is scaled twice. The short side keeps
    // portrait monitors from inflating it, and the smallest output wins so
    // no bar is oversized (the scale slider bumps it up if wanted).
    readonly property real autoScale: {
        const screens = Quickshell.screens
        let side = 0
        for (let i = 0; i < screens.length; i++) {
            const edge = Math.min(screens[i].width, screens[i].height)
            if (side === 0 || edge < side)
                side = edge
        }
        return Math.min(Math.max((side || 1080) / 1080, 0.75), 2.5)
    }

    // The bar's inset from the screen edges. Wm.qml sets mango's outer
    // gaps to the same value so windows float with the same margin.
    readonly property int edgeInset: Math.round(8 * autoScale)
    // matches border_radius in defaults.conf
    readonly property int barRadius: 8

    // In-bar elements follow autoScale × the scale slider. barHeight is a
    // floor: the window grows when scaled modules (26px at 1.0, + inset
    // above + 8px padding) outgrow it.
    readonly property real barScale: autoScale * barUserScale
    readonly property int fontSize: Math.round(13 * barScale)
    readonly property int iconSize: Math.round(15 * barScale)
    readonly property int moduleHeight: Math.round(26 * barScale)
    readonly property int effectiveBarHeight: Math.max(barHeight, moduleHeight + edgeInset + 8)

    // Popups follow the popup size slider (persisted to popup-scale), not
    // the screen resolution. Popout scales each card as a whole, so popups
    // are written at one set of sizes and never scale themselves.
    property real popupUserScale: 1.0
    readonly property real popupScale: popupUserScale

    StateFile {
        path: root.stateDir + "/bar-height"
        onLoadFailed: root._barStateLoads++
        onLoaded: {
            root._barStateLoads++
            const v = parseInt(text())
            if (!isNaN(v))
                root.barHeight = Math.min(Math.max(v, 32), 80)
        }
    }

    StateFile {
        path: root.stateDir + "/bar-scale"
        onLoadFailed: root._barStateLoads++
        onLoaded: {
            root._barStateLoads++
            const v = parseFloat(text())
            if (!isNaN(v))
                root.barUserScale = Math.min(Math.max(v, 0.7), 2.0)
        }
    }

    // the bar's modules: which zone each sits in (left, center, right),
    // in what order, shown or hidden — the Bar tab's Modules lists.
    // bar-modules holds one "zone key" per line, a "-" before the key
    // for hidden (a bare key means the right zone); no file = the
    // default below. Keys missing from the file (a new module) are
    // appended to their default zone. The launcher
    // (first, left) and the command menu (last, right) are fixed: they
    // host the launcher, settings, power and notification popups.
    readonly property var moduleDefs: [
        { key: "tags",       label: "Tags",           zone: "left" },
        { key: "layout",     label: "Layout button",  zone: "left" },
        { key: "title",      label: "Window title",   zone: "center" },
        { key: "media",      label: "Now playing",    zone: "right" },
        { key: "weather",    label: "Weather",        zone: "right" },
        { key: "metrics",    label: "CPU · RAM · disk", zone: "right" },
        { key: "volume",     label: "Volume",         zone: "right" },
        { key: "network",    label: "Network",        zone: "right" },
        { key: "updates",    label: "Updates",        zone: "right" },
        { key: "tray",       label: "Tray",           zone: "right" },
        { key: "bell",       label: "Notifications",  zone: "right" },
        { key: "clock",      label: "Clock",          zone: "right" },
        { key: "micmute",    label: "Mic mute",       zone: "right" },
        { key: "capslock",   label: "Caps lock",      zone: "right" },
        { key: "screenshot", label: "Screenshot",     zone: "right" }
    ]
    readonly property var zones: ["left", "center", "right"]
    function defaultModules() { return moduleDefs.map(d => ({ key: d.key, zone: d.zone, on: true })) }
    property var modules: defaultModules()
    function parseModules(t) {
        const out = []
        for (let l of t.split("\n")) {
            l = l.trim(); if (l === "") continue
            const parts = l.split(/\s+/)
            let zone = "right", key = parts[0]
            if (parts.length > 1 && zones.indexOf(parts[0]) >= 0) { zone = parts[0]; key = parts[1] }
            const on = key[0] !== "-"; if (!on) key = key.slice(1)
            if (moduleDefs.find(d => d.key === key) && !out.find(m => m.key === key)) out.push({ key: key, zone: zone, on: on })
        }
        for (const d of moduleDefs) if (!out.find(m => m.key === d.key)) out.push({ key: d.key, zone: d.zone, on: true })
        return out
    }
    function setModules(list) {
        modules = list
        writeState("bar-modules", list.map(m => m.zone + " " + (m.on ? "" : "-") + m.key).join("\n"))
    }
    // text and a newline to the state file name, as an argument, never
    // spliced into the shell; after (argv, optional) runs once it's written
    function writeState(name, text, after) {
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$2" > "$1" && shift 2 && exec "$@"',
                                 "sh", stateDir + "/" + name, String(text)].concat(after ?? []))
    }
    StateFile {
        path: root.stateDir + "/bar-modules"
        onLoaded: root.modules = root.parseModules(text())
        // the file deleted = back to the default
        onLoadFailed: root.modules = root.defaultModules()
    }

    // the Tags strip shows which apps sit on each tag (Bar tab toggle)
    property bool tagIcons: false
    StateFile {
        path: root.stateDir + "/tag-icons"
        onLoaded: root.tagIcons = text().trim() === "1"
    }
    // how many empty tags the strip shows (the first N, 0 = all) and
    // whether it hides them all; tags with windows always show (Bar tab)
    property int tagsShown: 0
    StateFile {
        path: root.stateDir + "/tags-shown"
        onLoaded: root.tagsShown = Math.max(parseInt(text()) || 0, 0)
        onLoadFailed: root.tagsShown = 0
    }
    property bool tagsHideEmpty: false
    StateFile {
        path: root.stateDir + "/tags-hide-empty"
        onLoaded: root.tagsHideEmpty = text().trim() === "1"
        onLoadFailed: root.tagsHideEmpty = false
    }

    // not part of barStateReady: popups aren't open at start
    StateFile {
        path: root.stateDir + "/popup-scale"
        onLoadFailed: root.popupUserScale = 1.0
        onLoaded: {
            const v = parseFloat(text())
            root.popupUserScale = isNaN(v) ? 1.0 : Math.min(Math.max(v, 0.8), 2.0)
        }
    }

    StateFile {
        path: root.stateDir + "/colors.ini"
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
        if (map["background-alt"]) altbg = map["background-alt"]
        if (map["foreground"]) fg = map["foreground"]
        if (map["border"]) border = map["border"]
        if (map["primary"]) primary = map["primary"]
        if (map["secondary"]) secondary = map["secondary"]
        if (map["alert"]) alert = map["alert"]
        if (map["disabled"]) disabled = map["disabled"]
    }
}
