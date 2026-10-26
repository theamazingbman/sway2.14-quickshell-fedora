import QtQuick

// A button of the settings panel's editors: label on a soft pill, or
// accent-filled when primary.
Btn {
    property string label: ""
    property bool primary: false
    text: label
    active: primary
    height: 28
    radius: 6
    padding: 24
    restColor: Qt.alpha(Theme.fg, 0.07)
    ink: primary ? Theme.bg : Theme.fg
}
