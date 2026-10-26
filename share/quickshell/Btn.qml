import QtQuick

// A pill button: text with an optional leading glyph, a soft fill that
// lifts on hover, activeColor while active. Callers pass their own size
// and colors. allowed: false dims it and ignores clicks. padding is
// added to the text width only; leave room in it for a glyph.
Rectangle {
    id: btn
    property string text: ""
    property string glyph: ""
    property bool active: false
    property bool allowed: true
    property bool bold: active
    property int fontSize: 11
    property int glyphSize: 13
    property int padding: 18
    property int spacing: 6
    property int fadeMs: 120
    property color restColor: Qt.alpha(Theme.fg, 0.06)
    property color hoverColor: Qt.alpha(Theme.fg, 0.14)
    property color activeColor: Theme.accent
    property color activeHoverColor: activeColor
    property color ink: active ? Theme.bg : Qt.alpha(Theme.fg, 0.8)
    property color glyphInk: active ? Theme.bg : Theme.cyan
    readonly property bool hovered: btnMa.containsMouse && allowed
    signal clicked()

    implicitWidth: btnText.implicitWidth + padding
    implicitHeight: 24
    radius: 8
    opacity: allowed ? 1 : 0.35
    color: active ? (hovered ? activeHoverColor : activeColor)
         : hovered ? hoverColor : restColor
    Behavior on color { enabled: btn.fadeMs > 0; ColorAnimation { duration: btn.fadeMs } }

    Row {
        anchors.centerIn: parent
        spacing: btn.spacing
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            visible: btn.glyph !== ""
            text: btn.glyph
            color: btn.glyphInk
            font.pixelSize: btn.glyphSize
        }
        Txt {
            id: btnText
            anchors.verticalCenter: parent.verticalCenter
            text: btn.text
            color: btn.ink
            font.pixelSize: btn.fontSize
            font.bold: btn.bold
        }
    }
    MouseArea {
        id: btnMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: btn.allowed ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (btn.allowed) btn.clicked()
    }
}
