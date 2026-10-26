import QtQuick

// Muted-mic warning: hidden until the default source is muted, then a red
// pill. Click unmutes; the Commands tile toggles it too.
BarModule {
    visible: Sys.micMuted
    icon: "󰍭"
    label: "Mic"
    alert: true
    onClicked: Sys.toggleMicMute()
}
