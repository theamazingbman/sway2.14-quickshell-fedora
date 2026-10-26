import QtQuick

// The layout grid and the live tweaks (gap, border, master width and
// count, effects), as a column for the settings panel's Layout tab. The
// grid shows the layout of the output the panel is on; a tile applies
// there (mmsg dispatch setlayout). Gap and effects persist to the
// mango-gaps / mango-effects state files Wm.qml re-applies on start.
Column {
    id: root
    readonly property string mon: Wm.monitor
    spacing: 6

    SectionLabel { text: "Layout" }

    Grid {
        id: layoutGrid
        width: parent.width
        columns: 3
        spacing: 4

        Repeater {
            model: Wm.layouts

            Rectangle {
                id: tile
                required property var modelData
                required property int index
                readonly property bool current: Wm.of(root.mon).layoutIndex === index

                width: (layoutGrid.width - 8) / 3
                height: 52
                radius: 8
                color: current ? Theme.selbg
                     : tileMa.containsMouse ? Qt.alpha(Theme.fg, 0.12)
                     : Qt.alpha(Theme.fg, 0.04)

                Behavior on color { ColorAnimation { duration: 120 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.glyph
                        color: tile.current ? Theme.selfg : Theme.cyan
                        font.pixelSize: 18
                    }
                    Txt {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.name
                        color: tile.current ? Theme.selfg : Qt.alpha(Theme.fg, 0.8)
                        font.pixelSize: 10
                        font.bold: tile.current
                    }
                }

                MouseArea {
                    id: tileMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Wm.setLayout(tile.index, root.mon)
                }
            }
        }
    }

    SectionLabel { text: "Desktop" }

    TweakSlider {
        label: "window gap"
        from: 0; to: 40
        value: Wm.gaps
        suffix: " px"
        applyFn: v => Wm.setGaps(v)
        persistFn: v => Theme.writeState("mango-gaps", v)
    }
    TweakSlider {
        label: "border width"
        from: 0; to: 6
        value: Wm.borderpx
        suffix: " px"
        applyFn: v => Wm.setBorder(v)
        persistFn: v => Wm.persistEffects()
    }
    // master sliders dim in layouts whose arrange ignores them
    TweakSlider {
        label: "master width"
        from: 20; to: 80
        value: Wm.mfact
        suffix: "%"
        applyFn: v => Wm.setMfact(v)
        persistFn: v => {}   // session state, nothing to persist
        enabled: Wm.layouts[Wm.of(root.mon).layoutIndex].mfact
        opacity: enabled ? 1 : 0.35
    }
    TweakSlider {
        label: "master count"
        from: 1; to: 6
        value: Wm.nmaster
        applyFn: v => Wm.setNmaster(v)
        persistFn: v => {}   // session state, nothing to persist
        enabled: Wm.layouts[Wm.of(root.mon).layoutIndex].nmaster
        opacity: enabled ? 1 : 0.35
    }

    SectionLabel { text: "Effects" }

    // live through setoption, persisted to mango-effects (Wm.qml)
    Grid {
        id: fxGrid
        width: parent.width
        columns: 3
        spacing: 4

        Repeater {
            model: [
                { icon: "󰂲", label: "Blur", active: Wm.blur,
                  run: () => Wm.setEffect("blur", !Wm.blur) },
                { icon: "󰘷", label: "Shadows", active: Wm.shadows,
                  run: () => Wm.setEffect("shadows", !Wm.shadows) },
                { icon: "󰐊", label: "Animate", active: Wm.animations,
                  run: () => Wm.setEffect("animations", !Wm.animations) }
            ]
            TogglePill { width: (fxGrid.width - 8) / 3 }
        }
    }
    // windows without focus fade toward the wallpaper; 100 = off.
    // With a thin border it is a second focus cue.
    TweakSlider {
        label: "unfocused opacity"
        from: 70; to: 100
        value: Wm.unfocusedOpacity
        suffix: "%"
        applyFn: v => Wm.setUnfocusedOpacity(v)
        persistFn: v => Wm.persistEffects()
    }
}
