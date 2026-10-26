import QtQuick

// A text field of the settings panel's editors: Enter accepts, Escape
// leaves the editor (the pane decides what each means), Tab moves to
// the next field (Qt's focus chain: the editor's fields in order).
Rectangle {
    id: field
    signal accepted()
    signal escaped()
    property alias text: ti.text
    property alias input: ti
    property string placeholder: ""
    height: 30
    radius: 6
    color: Qt.alpha(Theme.fg, 0.06)
    border.width: 1
    border.color: ti.activeFocus ? Qt.alpha(Theme.accent, 0.5) : "transparent"
    TextInput {
        id: ti
        activeFocusOnTab: true
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.fg
        selectionColor: Qt.alpha(Theme.accent, 0.4)
        font.family: Theme.fontFamily
        font.pixelSize: 12
        clip: true
        Keys.onEscapePressed: ev => { field.escaped(); ev.accepted = true }
        Keys.onReturnPressed: field.accepted()
        Keys.onEnterPressed: field.accepted()
    }
    Text {
        anchors.fill: ti
        verticalAlignment: Text.AlignVCenter
        visible: ti.text === ""
        text: field.placeholder
        color: Qt.alpha(Theme.fg, 0.35)
        font: ti.font
    }
}
