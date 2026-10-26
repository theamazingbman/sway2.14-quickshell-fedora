import QtQuick
import Quickshell

// The bar window, effectiveBarHeight px tall: a layer-shell panel, so
// mango reserves its exclusive zone and re-tiles live when the height
// changes.
PanelWindow {
    id: root

    property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.effectiveBarHeight
    color: "transparent"
    // map once, at final size — see Theme.barStateReady
    visible: Theme.barStateReady

    Rectangle {
        id: panel
        anchors.fill: parent
        // inset from the screen edges; the gap below comes from mango's
        // outer gaps (same value), so the bar and windows share one margin
        anchors.topMargin: Theme.edgeInset
        anchors.leftMargin: Theme.edgeInset
        anchors.rightMargin: Theme.edgeInset
        anchors.bottomMargin: 0

        radius: Theme.barRadius
        color: Qt.alpha(Theme.bg, 0.94)
        border.width: 1
        border.color: Qt.alpha(Theme.accent, 0.35)

        Behavior on color { ColorAnimation { duration: 400 } }
        Behavior on border.color { ColorAnimation { duration: 400 } }

        // A portrait monitor or a small laptop panel cannot hold every
        // pill. When the clusters would run into each other, the pills
        // that only repeat what another window shows step aside: media
        // first, then the CPU/RAM readout. The rest is summed without
        // those two, so hiding one cannot flip the answer back. Each slot
        // carries its gap in its width; media and metrics are found by key
        // wherever they sit.
        function slotFor(key) {
            for (const c of [leftCluster, centerCluster, rightCluster])
                for (let i = 0; i < c.children.length; i++)
                    if (c.children[i].key === key) return c.children[i]
            return null
        }
        // skipping media and metrics keeps their visibility out of the
        // sum (a binding loop through the cluster widths otherwise)
        readonly property real restWidth: {
            let w = 56
            for (const c of [leftCluster, centerCluster, rightCluster])
                for (let i = 0; i < c.children.length; i++) {
                    const k = c.children[i]
                    if (k.key === "media" || k.key === "metrics") continue
                    w += k.width
                }
            return w
        }
        function need(key) { const s = slotFor(key); return s && s.item ? s.item.implicitWidth + s.gap : 0 }
        readonly property real metricsNeed: need("metrics")
        readonly property real mediaNeed: need("media")
        readonly property bool fitsMetrics: restWidth + metricsNeed <= width
        readonly property bool fitsMedia: restWidth + metricsNeed + mediaNeed <= width

        // right-click empty bar = the layout/tweaks picker (same popup
        // as clicking the layout button); declared before the clusters
        // so module mouse areas stack above it
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: BarIpc.call("settings", "open", "layout")
        }

        // Three zones, each a Row of the modules Theme.modules puts there
        // (the Bar tab's Modules lists), in order. The launcher opens the
        // left zone and the command menu closes the right one, fixed: they
        // host the popups. Looked up when a slot asks: a map built at
        // construction would see the Component ids before they exist.
        function componentFor(key) {
            switch (key) {
            case "tags": return cTags;          case "layout": return cLayout
            case "title": return cTitle
            case "media": return cMedia;        case "weather": return cWeather
            case "metrics": return cMetrics;    case "volume": return cVolume
            case "network": return cNetwork;    case "updates": return cUpdates
            case "tray": return cTray;          case "bell": return cBell
            case "clock": return cClock;        case "micmute": return cMicMute
            case "capslock": return cCapsLock;  case "screenshot": return cScreenshot
            }
            return null
        }
        Component { id: cTags; Tags {} }
        Component { id: cLayout; LayoutButton {} }
        Component { id: cTitle; Title {} }
        Component { id: cMedia; Media { allowed: panel.fitsMedia } }
        Component { id: cWeather; Weather {} }
        Component { id: cMetrics; Metrics { visible: panel.fitsMetrics } }
        Component { id: cVolume; Volume {} }
        Component { id: cNetwork; Network {} }
        Component { id: cUpdates; Updates {} }
        Component { id: cTray; Tray {} }
        Component { id: cBell; Bell {} }
        Component { id: cClock; Clock {} }
        Component { id: cMicMute; MicMute {} }
        Component { id: cCapsLock; CapsLock {} }
        Component { id: cScreenshot; Screenshot {} }

        // the room the window title has in its zone: the space between the
        // neighbouring clusters less its siblings (it elides to that; under
        // 40px it hides). Summed by hand to keep the title's own width out
        // (a binding loop otherwise).
        function titleRoom(slot) {
            const c = slot.parent
            let others = 0
            for (let i = 0; i < c.children.length; i++) {
                const k = c.children[i]
                if (k !== slot && k.width > 0) others += k.width
            }
            const mid = width / 2
            const leftEnd = leftCluster.x + leftCluster.width + 24
            const rightStart = rightCluster.x - 24
            if (c === centerCluster) return 2 * Math.min(mid - leftEnd, rightStart - mid) - others
            const centerOn = centerCluster.width > 0
            if (c === leftCluster) return (centerOn ? centerCluster.x : rightCluster.x) - 24 - leftCluster.x - others
            return rightCluster.x + rightCluster.width - ((centerOn ? centerCluster.x + centerCluster.width : leftCluster.x + leftCluster.width) + 24) - others
        }

        // one module's place in a zone: carries the gap after it, so a
        // hidden module leaves no double spacing; the loader is always
        // visible itself (binding to the item's visibility is circular:
        // a hidden parent hides the child) and collapses instead
        component Slot: Item {
            id: slot
            required property var modelData
            readonly property string key: modelData.key
            readonly property int gap: parent.gap
            readonly property bool isTitle: key === "title"
            readonly property var item: ld.item
            readonly property bool shown: ld.item !== null && ld.item.visible
            readonly property real fit: !ld.item ? 0
                : isTitle ? Math.max(0, Math.min(ld.item.implicitWidth, panel.titleRoom(slot))) : ld.item.implicitWidth
            anchors.verticalCenter: parent.verticalCenter
            width: shown && (!isTitle || fit >= 40) ? fit + gap : 0
            height: ld.item ? ld.item.implicitHeight : 0
            Loader {
                id: ld
                anchors.verticalCenter: parent.verticalCenter
                sourceComponent: panel.componentFor(slot.key)
                width: slot.fit
                height: slot.height
            }
        }

        Row {
            id: leftCluster
            readonly property int gap: 8
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Launcher {}
            Item { width: leftCluster.gap; height: 1 }
            Repeater {
                model: Theme.modules.filter(m => m.on && m.zone === "left")
                Slot {}
            }
        }

        Row {
            id: centerCluster
            readonly property int gap: 8
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: gap / 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Repeater {
                model: Theme.modules.filter(m => m.on && m.zone === "center")
                Slot {}
            }
        }

        Row {
            id: rightCluster
            readonly property int gap: 4
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Repeater {
                model: Theme.modules.filter(m => m.on && m.zone === "right")
                Slot {}
            }
            // always here: it hosts the settings panel, the power menu and
            // the notification popups (Super+/, Super+x reach them by ipc)
            Commands {}
        }
    }
}
