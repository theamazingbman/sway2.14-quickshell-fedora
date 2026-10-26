import QtQuick

// Now playing (MediaState), hidden when nothing plays. Click toggles
// play/pause, scroll skips tracks, right click opens the popup (art, seek,
// transport, player switcher), middle click dismisses that player on every
// output until it changes track or plays after a pause. The pill is a truncated
// title plus a progress underline when the track reports a length.
BarModule {
    id: root

    readonly property var player: MediaState.player

    // false on a bar too narrow for it (Bar.qml)
    property bool allowed: true

    visible: allowed && MediaState.shown

    icon: MediaState.playing ? "󰐊" : "󰏤"
    iconColor: Theme.magenta
    label: {
        if (!player)
            return ""
        const t = MediaState.artistText !== "" ? MediaState.artistText + " — " + player.trackTitle
                                               : (player.trackTitle ?? "")
        return t.length > 26 ? t.slice(0, 24) + "…" : t
    }
    progress: MediaState.timed ? Math.min(MediaState.pos / MediaState.len, 1) : -1

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            popup.visible = !popup.visible
        } else if (mouse.button === Qt.MiddleButton) {
            MediaState.dismiss(player)
            popup.visible = false
        } else if (player && player.canTogglePlaying) {
            player.togglePlaying()
        }
    }
    onScrolled: dir => {
        if (!player)
            return
        if (dir > 0 && player.canGoPrevious)
            player.previous()
        else if (dir < 0 && player.canGoNext)
            player.next()
    }

    MediaPopup {
        id: popup
        anchorItem: root
        media: MediaState
    }
}
