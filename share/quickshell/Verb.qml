import QtQuick
import Quickshell.Io

// Runs a settings back end, one verb at a time: run(script, args, cb)
// calls cb(exit code, stdout and stderr together).
Process {
    id: proc
    property var done: null
    function run(script, args, cb) {
        done = cb
        command = ["sh", "-c", 'o=$("$0" "$@" 2>&1); r=$?; printf "%s\\n%s" "$r" "$o"', script].concat(args)
        running = true
    }
    stdout: StdioCollector {
        onStreamFinished: {
            const f = proc.done
            proc.done = null
            const i = text.indexOf("\n")
            if (f) f(parseInt(text.slice(0, i)), text.slice(i + 1))
        }
    }
}
