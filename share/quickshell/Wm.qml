pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Sway backend for the shared Mangobutter shell. Uses standard swaymsg IPC;
// Mango-only visual effects and layouts are intentionally disabled.
Singleton {
    id: root
    property string monitor: ""
    property var mons: ({})
    property var tagApps: ({})
    property bool identifyOutputs: false
    readonly property var _none: ({seltags:1, occtags:0, urgtags:0, tagCount:10, title:"", appid:"", layoutIndex:0})
    function of(name) { return mons[name] ?? mons[monitor] ?? _none }
    readonly property var layouts: [
        {name:"splith", id:"splith", symbol:"H", glyph:"󰕰", mfact:false, nmaster:false},
        {name:"splitv", id:"splitv", symbol:"V", glyph:"󰕰", mfact:false, nmaster:false},
        {name:"tabbed", id:"tabbed", symbol:"T", glyph:"󰓩", mfact:false, nmaster:false},
        {name:"stacking", id:"stacking", symbol:"S", glyph:"󰓩", mfact:false, nmaster:false}
    ]
    property int gaps: 5
    property int mfact: 55
    property int nmaster: 1
    property bool blur: false
    property bool shadows: false
    property bool animations: false
    property int borderpx: 2
    property int unfocusedOpacity: 100
    property bool effectsFromFile: false
    readonly property var sessionProcs: /^(sway|Xwayland|swayidle|qs|wl-paste)$/

    function run(args) { Quickshell.execDetached(args) }
    function dispatch(cmd) { run(["swaymsg", cmd]) }
    function dispatchOn(mon, cmd) { dispatch(cmd) }
    function setLayout(i, mon) {
        const l = layouts[i] ? layouts[i].id : "splith"
        dispatch("layout " + l)
    }
    function cycleLayout(dir, mon) {
        const i = ((of(mon).layoutIndex + dir) % layouts.length + layouts.length) % layouts.length
        setLayout(i, mon)
    }
    function viewTag(i, mon) { dispatch("workspace number " + (i + 1)) }
    function sendToTag(i, mon) { dispatch("move container to workspace number " + (i + 1)) }
    function cycleTag(dir, mon) { dispatch("workspace next_on_output") }
    function logout() { dispatch("exit") }
    function reloadConfig() { dispatch("reload") }
    function applyGaps(v) { gaps = v; dispatch("gaps inner " + v) }
    function applyOuterGaps() { dispatch("gaps outer " + Theme.edgeInset) }
    function setGaps(v) { gaps = v; applyGaps(v); applyOuterGaps() }
    function setMfact(pct) { mfact = pct }
    function setNmaster(n) { nmaster = n }
    function setBorder(v) { borderpx = v; dispatch("default_border pixel " + v) }
    function setUnfocusedOpacity(v) { unfocusedOpacity = v }
    function setEffect(name, on) { root[name] = on }
    function persistEffects() {}
    function applyEffects() {}
    function elsewhere(mon) { return false }

    Process {
        id: workspacesProc
        command: ["swaymsg", "-r", "-t", "get_workspaces"]
        running: true
        stdout: StdioCollector { id: wsOut }
        onExited: {
            try { root.parseWorkspaces(wsOut.text) } catch (e) {}
            refreshTimer.restart()
        }
    }
    Process {
        id: treeProc
        command: ["swaymsg", "-r", "-t", "get_tree"]
        running: true
        stdout: StdioCollector { id: treeOut }
        onExited: {
            try { root.parseTree(treeOut.text) } catch (e) {}
            refreshTimer.restart()
        }
    }
    Process {
        id: outputsProc
        command: ["swaymsg", "-r", "-t", "get_outputs"]
        running: true
        stdout: StdioCollector { id: outOut }
        onExited: {
            try { root.parseOutputs(outOut.text) } catch (e) {}
            refreshTimer.restart()
        }
    }
    Timer {
        id: refreshTimer
        interval: 900
        repeat: false
        onTriggered: {
            if (!workspacesProc.running) workspacesProc.running = true
            if (!treeProc.running) treeProc.running = true
            if (!outputsProc.running) outputsProc.running = true
        }
    }
    function parseOutputs(raw) {
        const outs = JSON.parse(raw)
        const next = {}
        for (const o of outs) next[o.name] = _none
        mons = Object.assign({}, mons, next)
        const focused = outs.find(o => o.focused)
        if (focused) monitor = focused.name
    }
    function parseWorkspaces(raw) {
        const ws = JSON.parse(raw)
        const next = {}
        const names = {}
        for (const w of ws) {
            const output = w.output || monitor
            if (!next[output]) next[output] = {seltags:0,occtags:0,urgtags:0,tagCount:10,title:"",appid:"",layoutIndex:0}
            const n = parseInt(w.name, 10)
            if (n >= 1 && n <= 10) {
                if (w.focused) next[output].seltags |= (1 << (n - 1))
                if (w.num_windows > 0) next[output].occtags |= (1 << (n - 1))
            }
        }
        mons = Object.assign({}, mons, next)
    }
    function parseTree(raw) {
        const tree = JSON.parse(raw)
        const nextApps = {}
        function visit(n, output, workspace) {
            if (!n) return
            let out = output, ws = workspace
            if (n.type === "output") out = n.name
            if (n.type === "workspace") ws = n.name
            if (n.type === "con" && n.window_properties && n.focused) {
                const m = Object.assign({}, root.mons[out] ?? root._none)
                m.title = n.name || ""
                m.appid = n.app_id || n.window_properties.class || ""
                const a = Object.assign({}, root.mons); a[out] = m; root.mons = a
            }
            if (n.type === "con" && n.window) {
                const idx = parseInt(ws, 10) - 1
                if (idx >= 0 && idx < 10) {
                    if (!nextApps[out]) nextApps[out] = ({})
                    if (!nextApps[out][idx]) nextApps[out][idx] = []
                    const app = n.app_id || n.window_properties?.class || ""
                    const icon = root.appIcon(app)
                    const hit = nextApps[out][idx].find(x => x.appid === app)
                    if (hit) hit.count++
                    else nextApps[out][idx].push({appid:app,icon:icon,count:1})
                }
            }
            for (const c of n.nodes ?? []) visit(c, out, ws)
            for (const c of n.floating_nodes ?? []) visit(c, out, ws)
        }
        visit(tree, "", "")
        tagApps = nextApps
    }
    property var _iconCache: ({})
    function appIcon(appid) {
        if (_iconCache[appid] !== undefined) return _iconCache[appid]
        const entry = DesktopEntries.heuristicLookup(appid)
        const icon = entry?.icon ? Quickshell.iconPath(entry.icon, "application-x-executable") : ""
        _iconCache[appid] = icon
        return icon
    }
}
