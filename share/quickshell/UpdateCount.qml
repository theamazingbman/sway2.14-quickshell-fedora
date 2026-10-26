pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Pending apt upgrades, counted once for every output's bar: a root-free,
// lock-free simulated dist-upgrade, hourly and on `qs ipc call updates
// check` (the upgrade terminal calls it when apt finishes). As fresh as
// the last `apt update`.
Singleton {
    id: root

    property int count: 0
    function check() { proc.running = true }

    Process {
        id: proc
        command: ["sh", "-c",
            "apt-get -s -o Debug::NoLocking=1 dist-upgrade 2>/dev/null | grep -c '^Inst'"]
        stdout: StdioCollector {
            onStreamFinished: root.count = parseInt(text.trim()) || 0
        }
    }
    Timer {
        interval: 3600 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.check()
    }
    Connections {
        target: BarIpc
        function onCall(target, fn, arg) {
            if (target === "updates" && fn === "check") root.check()
        }
    }
}
