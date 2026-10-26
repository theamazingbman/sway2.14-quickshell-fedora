import QtQuick
import Quickshell.Services.Mpris

// Now-playing popup (right-click the Media module): art, track info,
// click-to-seek, transport buttons, and a player picker when more than
// one MPRIS player is up. State comes from the Media module (`media`)
// so the two never disagree.
Popout {
    id: root

    required property var media
    readonly property var player: media.player

    // players don't announce position while paused, so read it on open
    onVisibleChanged: if (visible) media.pos = player?.position ?? 0

    cardWidth: 320
    cardHeight: col.implicitHeight + 2 * cardPadding

    // soft for previous / next, accent for play / pause (active)
    component TransportButton: Btn {
        anchors.verticalCenter: parent.verticalCenter
        width: active ? 52 : 40
        height: active ? 36 : 32
        fontSize: active ? 20 : 16
        bold: false
        restColor: Qt.alpha(Theme.fg, 0.07)
        activeHoverColor: Qt.lighter(Theme.accent, 1.15)
        ink: active ? Theme.bg : Theme.fg
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        Row {
            width: parent.width
            spacing: 12

            Rectangle {
                id: artFrame
                width: 84
                height: 84
                radius: 8
                color: Qt.alpha(Theme.fg, 0.06)
                clip: true

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    // decode at twice the frame, not the art's full size
                    sourceSize: Qt.size(168 * root.s, 168 * root.s)
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
                Txt {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: "󰝚"
                    color: Qt.alpha(Theme.fg, 0.3)
                    font.pixelSize: 30
                }
            }

            Column {
                width: parent.width - artFrame.width - parent.spacing
                anchors.verticalCenter: artFrame.verticalCenter
                spacing: 3

                Txt {
                    width: parent.width
                    text: root.player?.trackTitle ?? ""
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                }
                Txt {
                    width: parent.width
                    text: root.media.artistText
                    color: Qt.alpha(Theme.fg, 0.75)
                    elide: Text.ElideRight
                }
                Txt {
                    width: parent.width
                    visible: (root.player?.trackAlbum ?? "") !== ""
                    text: root.player?.trackAlbum ?? ""
                    color: Qt.alpha(Theme.fg, 0.5)
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
                Txt {
                    width: parent.width
                    text: root.player?.identity ?? ""
                    color: Qt.alpha(Theme.accent, 0.7)
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
        }

        // click-to-seek; hidden for streams that report no length
        Item {
            width: parent.width
            height: 30
            visible: root.media.timed

            Txt {
                anchors.left: parent.left
                anchors.top: parent.top
                text: root.media.fmt(root.media.pos)
                color: Qt.alpha(Theme.fg, 0.6)
            }
            Txt {
                anchors.right: parent.right
                anchors.top: parent.top
                text: root.media.fmt(root.media.len)
                color: Qt.alpha(Theme.fg, 0.6)
            }

            Rectangle {
                id: seekTrack
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 3
                height: 4
                radius: 2
                color: Qt.alpha(Theme.fg, 0.12)

                readonly property real frac: Math.min(Math.max(root.media.pos / root.media.len, 0), 1)
                Rectangle {
                    width: seekTrack.frac * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: Theme.accent
                }
                // the popup sliders' knob
                Rectangle {
                    x: seekTrack.frac * parent.width - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: Theme.fg
                    border.width: 2
                    border.color: Theme.bg
                }
            }
            MouseArea {
                anchors.fill: parent
                anchors.topMargin: 10
                enabled: root.player?.canSeek ?? false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: m => {
                    const frac = Math.min(Math.max(m.x / width, 0), 1)
                    root.player.position = frac * root.media.len
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            TransportButton {
                text: "󰒮"
                allowed: root.player?.canGoPrevious ?? false
                onClicked: root.player.previous()
            }
            TransportButton {
                active: true
                text: root.media.playing ? "󰏤" : "󰐊"
                allowed: root.player?.canTogglePlaying ?? false
                onClicked: root.player.togglePlaying()
            }
            TransportButton {
                text: "󰒭"
                allowed: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }
        }

        // other players, only when there's a choice to make
        Repeater {
            model: Mpris.players.values.length > 1 ? Mpris.players.values : []

            ListRow {
                required property var modelData
                active: modelData === root.player
                check: true
                glyph: modelData.playbackState === MprisPlaybackState.Playing ? "󰐊" : "󰏤"
                text: modelData.identity
                onClicked: root.media.manual = modelData
            }
        }
    }
}
