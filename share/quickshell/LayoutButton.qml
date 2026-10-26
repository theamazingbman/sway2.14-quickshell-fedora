import QtQuick
import Quickshell

// Current layout as its nerd-font glyph. Scroll cycles layouts, click
// opens the settings panel's Layout tab.
BarModule {
    id: root

    readonly property string mon: QsWindow.window?.screen?.name ?? ""
    icon: Wm.layouts[Wm.of(mon).layoutIndex].glyph
    iconColor: Theme.fg

    onClicked: BarIpc.call("settings", "open", "layout")
    onScrolled: dir => Wm.cycleLayout(dir, mon)
}
