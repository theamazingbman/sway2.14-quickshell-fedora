import QtQuick

// The editor under a settings list while an entry is open: a title, the
// caller's rows of fields, then Save / Cancel / Delete and the status.
// Lbl is a row's caption. Delete shows for an entry already in the file.
Rectangle {
    id: panel
    property var editing: null      // the open entry, null = closed
    property string title
    property string status
    property bool statusBad: false
    readonly property real innerWidth: edCol.width
    default property alias rows: fieldCol.data
    signal save()
    signal cancel()
    signal remove()

    component Lbl: Txt {
        width: 110
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.alpha(Theme.fg, 0.7)
    }

    visible: editing !== null
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: edCol.implicitHeight + 24
    radius: 10
    color: Qt.alpha(Theme.fg, 0.05)
    border.width: 1
    border.color: Qt.alpha(Theme.accent, 0.3)

    Column {
        id: edCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        // which entry this is, so a wrong click shows before you type
        Txt {
            width: parent.width
            text: panel.title
            color: Theme.accent
            font.bold: true
            font.pixelSize: 12
            elide: Text.ElideRight
        }
        Column {
            id: fieldCol
            width: parent.width
            spacing: 8
        }
        Row {
            spacing: 8
            EditButton { label: "Save"; primary: true; onClicked: panel.save() }
            EditButton { label: "Cancel"; onClicked: panel.cancel() }
            EditButton { visible: panel.editing && !panel.editing.isNew; label: "Delete"; ink: Theme.red; onClicked: panel.remove() }
            // why a save was refused, right where Save is
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 8
                width: edCol.width - 300
                elide: Text.ElideRight
                visible: panel.status !== ""
                text: panel.status
                color: panel.statusBad ? Theme.red : Qt.alpha(Theme.fg, 0.7)
                font.bold: panel.statusBad
            }
        }
    }
}
