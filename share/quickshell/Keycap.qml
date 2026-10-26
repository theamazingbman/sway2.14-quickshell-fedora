import QtQuick

// One key of a chord on a bordered cap. cap: false is bare dim text,
// the "/" between alternatives.
Rectangle {
    property alias text: capText.text
    property bool cap: true
    implicitWidth: capText.implicitWidth + (cap ? 12 : 2)
    implicitHeight: 20
    radius: 4
    color: cap ? Qt.alpha(Theme.fg, 0.08) : "transparent"
    border.width: cap ? 1 : 0
    border.color: Qt.alpha(Theme.fg, 0.16)
    Txt {
        id: capText
        anchors.centerIn: parent
        color: parent.cap ? Theme.fg : Qt.alpha(Theme.fg, 0.4)
    }
}
