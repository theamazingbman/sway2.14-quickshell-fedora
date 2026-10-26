import QtQuick

// Debian swirl — the command center, no extra buttons needed:
//   left: app launcher (LauncherPopup) · right: the settings panel's
//   Wallpaper tab · middle: random wallpaper
// Both wallpaper paths re-theme the desktop from the image's palette.
// FiraCode NF carries the Font Logos glyph; JetBrainsMono NF here doesn't.
BarModule {
    id: root

    icon: ""  // Debian swirl (Font Logos)
    iconFont: "FiraCode Nerd Font"
    iconColor: Theme.accent
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            BarIpc.call("settings", "open", "wallpaper")
        else if (mouse.button === Qt.MiddleButton)
            BarIpc.call("wallpapers", "random", "")
        else
            launcher.visible = !launcher.visible
    }

    LauncherPopup {
        id: launcher
        anchorItem: root
    }
}
