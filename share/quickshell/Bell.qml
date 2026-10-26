import QtQuick

// Do-not-disturb indicator: a red bell-off icon, shown only while DND is
// on. Click resumes notifications, right click opens the history; the
// Commands tile toggles it too.
BarModule {
    id: root

    visible: Sys.dndOn
    icon: "󰂛"
    iconColor: Theme.red

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            history.visible = !history.visible
        else
            Sys.toggleDnd()
    }

    NotifyPopup {
        id: history
        anchorItem: root
    }
}
