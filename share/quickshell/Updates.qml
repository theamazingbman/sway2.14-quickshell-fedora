import QtQuick
import Quickshell

// Pending-updates pill (UpdateCount), hidden at zero. Click opens the
// upgrade terminal; middle click re-checks now.
BarModule {
    id: root

    visible: UpdateCount.count > 0
    icon: "󰚰"
    iconColor: Theme.accent
    label: String(UpdateCount.count)

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) {
            UpdateCount.check()
        } else {
            // ...and, since updates were asked for, one look at whether the
            // setup itself has moved on (scripts/setup-update offer)
            Quickshell.execDetached(["kitty", "-e", "sh", "-c",
                "sudo apt update && sudo apt full-upgrade; " +
                "qs -p \"$0\" ipc call updates check >/dev/null 2>&1; " +
                "\"$1\" offer; " +
                "printf '\\ndone - press enter to close '; read _",
                Theme.shareDir + "/quickshell", Theme.shareDir + "/scripts/setup-update"])
        }
    }
}
