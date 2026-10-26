import QtQuick

// A popup list row: glyph column and label, a hover lift, activeColor
// while active. check: the glyph turns into a check mark while active.
Rectangle {
    id: row
    property string glyph: ""
    property string text: ""
    property bool active: false
    property bool check: false
    property bool pointer: true
    property int glyphSize: 14
    property int fontSize: 12
    property int glyphWidth: 16
    property int leftMargin: 10
    property color activeColor: Qt.alpha(Theme.accent, 0.18)
    property color hoverColor: Qt.alpha(Theme.fg, 0.12)
    property color glyphInk: active ? Theme.accent : Theme.cyan
    property color ink: active ? Theme.fg : Qt.alpha(Theme.fg, 0.9)
    signal clicked()

    width: parent.width
    implicitHeight: 32
    radius: 8
    color: active ? activeColor : rowMa.containsMouse ? hoverColor : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    Txt {
        id: rowGlyph
        anchors.left: parent.left
        anchors.leftMargin: row.leftMargin
        anchors.verticalCenter: parent.verticalCenter
        width: row.glyphWidth > 0 ? row.glyphWidth : implicitWidth
        horizontalAlignment: Text.AlignHCenter
        text: row.check && row.active ? "󰄬" : row.glyph
        color: row.glyphInk
        font.pixelSize: row.glyphSize
    }
    Txt {
        anchors.left: rowGlyph.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: row.text
        elide: Text.ElideRight
        color: row.ink
        font.pixelSize: row.fontSize
        font.bold: row.active
    }
    MouseArea {
        id: rowMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: row.pointer ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: row.clicked()
    }
}
