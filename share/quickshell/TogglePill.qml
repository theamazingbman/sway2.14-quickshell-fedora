import QtQuick

// Toggle pill for the tweaks grids: filled = on, click runs modelData.run.
// Width defaults to a 2-column grid; override it for other grids.
Rectangle {
    id: pill
    required property var modelData
    readonly property bool on: modelData.active === true

    width: (parent.width - 6) / 2
    height: 40
    radius: 12
    color: on ? Theme.selbg
         : pillMa.containsMouse ? Qt.alpha(Theme.fg, 0.12)
         : Qt.alpha(Theme.fg, 0.05)

    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        anchors.centerIn: parent
        spacing: 7

        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: pill.modelData.icon
            color: pill.on ? Theme.selfg : Theme.cyan
            font.pixelSize: 15
            Behavior on color { ColorAnimation { duration: 250 } }
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: pill.modelData.label
            color: pill.on ? Theme.selfg : Qt.alpha(Theme.fg, 0.9)
            font.pixelSize: 12
            font.bold: pill.on
        }
    }

    MouseArea {
        id: pillMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: pill.modelData.run()
        // the wheel stops here, so the pane doesn't scroll under the pill
        onWheel: {}
    }
}
