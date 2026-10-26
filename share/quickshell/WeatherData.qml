pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// The weather, fetched once for every output's bar: wttr.in (no API key)
// every 30 minutes, right away when the location changes, and again in
// 3 minutes after a failure. Location: weather-location in the state
// folder (a city or zip; absent = by IP, the VPN exit while a VPN is up).
// Units: weather-units "f" or "c"; absent = from the locale.
Singleton {
    id: root

    property string temp: ""          // "" until the first fetch
    property int code: 113
    property string condition: ""
    property string feels: ""
    property string wind: ""
    property string place: ""
    property real lat: 0
    property real lon: 0
    property var days: []             // {label, glyph, hi, lo, rain}
    property bool failed: false

    property string unitsOverride: ""
    property string location: ""
    readonly property bool useF: unitsOverride === "f" ? true
                               : unitsOverride === "c" ? false
                               : Qt.locale().measurementSystem !== Locale.MetricSystem

    FileView {
        path: Theme.stateDir + "/weather-units"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.unitsOverride = text().trim().toLowerCase()
        onLoadFailed: root.unitsOverride = "" // removed: back to auto
    }
    // a change refetches; so does deleting the file (loadFailed), but not
    // its absence at start, which the first fetch already covers
    FileView {
        path: Theme.stateDir + "/weather-location"
        watchChanges: true
        onFileChanged: { reload(); root.refetch() }
        onLoaded: root.location = text().trim()
        onLoadFailed: {
            if (root.location === "")
                return
            root.location = ""
            root.refetch()
        }
    }

    property var lastJson: null
    onUseFChanged: if (lastJson) parse(lastJson)

    // WWO condition codes → a handful of glyph buckets
    function glyphFor(c) {
        if ([200, 386, 389, 392, 395].indexOf(c) !== -1) return "󰖓"
        if ([179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335,
             338, 350, 368, 371, 374, 377].indexOf(c) !== -1) return "󰖘"
        if ([143, 248, 260].indexOf(c) !== -1) return "󰖑"
        if (c === 113) return "󰖙"
        if (c === 116) return "󰖕"
        if (c === 119 || c === 122) return "󰖐"
        return "󰖗"  // everything else in WWO's table is some kind of rain
    }

    property string _buf: ""
    function refetch() { fetch.running = false; fetch.running = true }
    Process {
        id: fetch
        command: ["sh", "-c",
            "LOC=$(tr -d '\\n' < \"$1\" 2>/dev/null | tr ' ' '+'); " +
            "curl -sf -m 10 \"https://wttr.in/${LOC}?format=j1\"",
            "sh", Theme.stateDir + "/weather-location"]
        running: true
        stdout: SplitParser {
            onRead: line => root._buf += line
        }
        onRunningChanged: if (running) root._buf = ""
        // st 1 = killed by a restart (a new location): the next run
        // answers. Otherwise curl's verdict counts — an unknown location
        // (404) or no network — and the card says so.
        onExited: (code, st) => {
            if (st !== 0)
                return
            try {
                if (code !== 0)
                    throw new Error("curl " + code)
                root.parse(JSON.parse(root._buf))
                root.failed = false
            } catch (e) {
                root.failed = true
                retry.start()
            }
        }
    }

    function parse(j) {
        lastJson = j
        const f = useF
        const c = j.current_condition[0]
        temp = f ? c.temp_F : c.temp_C
        code = parseInt(c.weatherCode) || 113
        condition = c.weatherDesc?.[0]?.value ?? ""
        const a = j.nearest_area?.[0]
        place = a ? [a.areaName?.[0]?.value,
                     a.region?.[0]?.value || a.country?.[0]?.value]
                     .filter(Boolean).join(", ") : ""
        lat = parseFloat(a?.latitude) || 0
        lon = parseFloat(a?.longitude) || 0
        feels = (f ? c.FeelsLikeF : c.FeelsLikeC) ?? ""
        wind = f ? (c.windspeedMiles ? c.windspeedMiles + "mph" : "")
                 : (c.windspeedKmph ? c.windspeedKmph + "km/h" : "")

        const out = []
        const names = ["today", "tomorrow"]
        for (let i = 0; i < Math.min(3, (j.weather ?? []).length); i++) {
            const d = j.weather[i]
            const noon = d.hourly?.[4] ?? d.hourly?.[0] ?? {}
            let rain = 0
            for (const h of d.hourly ?? [])
                rain = Math.max(rain, parseInt(h.chanceofrain) || 0)
            out.push({
                label: names[i] ?? new Date(d.date + "T12:00").toLocaleDateString(Qt.locale(), "ddd"),
                glyph: glyphFor(parseInt(noon.weatherCode) || 113),
                hi: (f ? d.maxtempF : d.maxtempC) ?? "?",
                lo: (f ? d.mintempF : d.mintempC) ?? "?",
                rain: rain
            })
        }
        days = out
    }

    Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.refetch()
    }
    Timer {
        id: retry
        interval: 3 * 60 * 1000
        onTriggered: root.refetch()
    }
}
