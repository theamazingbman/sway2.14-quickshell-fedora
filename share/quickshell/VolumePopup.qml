import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Volume popup (click the Volume module): the output and its mute pill,
// volume and output picker, a card's profiles when it has more than one
// (HDMI needs an HDMI profile), the microphone with a live meter, each
// playing app's volume, and pavucontrol. Read live from PipeWire.
Popout {
    id: root
    ipcNames: ["volume"]

    cardWidth: 340
    cardHeight: col.implicitHeight + 2 * cardPadding

    // filter only on what a node has before it's bound (type, name), or
    // binding would change the list and rebind it forever
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
    // microphones only: cameras are non-stream nodes too
    readonly property var sources: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)
    // what apps are playing (output streams; the meter below is an input
    // stream, so it never shows), grouped by app: Firefox's four tabs are
    // one Firefox slider that moves them all
    readonly property var outStreams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioOutStream)
    readonly property var apps: {
        const groups = []
        for (const n of outStreams) {
            const name = appLabel(n)
            const g = groups.find(g => g.name === name)
            if (g) g.nodes.push(n)
            else groups.push({ name: name, nodes: [n] })
        }
        return groups
    }

    // bound so their volume and mute stay live
    PwObjectTracker { objects: root.sinks.concat(root.sources, root.outStreams) }

    // the cards' profiles, read when the popup opens and after a change
    property var profiles: []   // {card, desc, profile, label, active}
    readonly property var cards: {
        const out = []
        for (const p of profiles) {
            let c = out.find(x => x.card === p.card)
            if (!c) { c = { card: p.card, desc: p.desc, rows: [] }; out.push(c) }
            c.rows.push(p)
        }
        return out.filter(c => c.rows.length > 1)
    }
    Process {
        id: profilesRead
        command: [Theme.shareDir + "/scripts/audio-profiles"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const l of text.split("\n")) {
                    const f = l.split("\t")
                    if (f.length >= 5) out.push({ card: f[0], desc: f[1], profile: f[2], label: f[3], active: f[4] === "1" })
                }
                root.profiles = out
            }
        }
    }
    Process {
        id: profileSet
        onExited: profilesRead.running = true
    }
    function setProfile(card, profile) {
        profileSet.command = [Theme.shareDir + "/scripts/audio-profiles", "set", card, profile]
        profileSet.running = true
    }
    onVisibleChanged: if (visible) profilesRead.running = true

    readonly property var current: Pipewire.defaultAudioSink
    readonly property var audio: current?.audio ?? null
    // the default source only if it is a microphone: with none chosen,
    // PipeWire can hand back an output, and "mute input" would mute it
    readonly property var mic: Pipewire.defaultAudioSource?.type === PwNodeType.AudioSource
                               ? Pipewire.defaultAudioSource : null
    readonly property var micAudio: mic?.audio ?? null

    // the microphone's live level, only while the popup is open
    PwNodePeakMonitor {
        id: meter
        node: root.mic
        enabled: root.visible && root.mic !== null
    }

    function label(n) {
        return n.description || n.nickname || n.name
    }
    function appLabel(n) {
        return n.properties?.["application.name"] || n.name || "app"
    }
    function pct(a) {
        return a ? Math.round(a.volume * 100) : 0
    }

    // red while muted
    component MutePill: Btn {
        glyph: active ? "󰖁" : "󰕾"
        text: active ? "muted" : "mute"
        activeColor: Theme.red
        restColor: Qt.alpha(Theme.fg, 0.07)
        ink: active ? Theme.bg : Theme.fg
        padding: 36
        fadeMs: 150
    }

    // the default device highlighted
    component DeviceRow: ListRow {
        required property var modelData
        property var chosen: null
        active: modelData === chosen
        check: true
        text: root.label(modelData)
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6

        // --- header: what you're hearing ---
        Item {
            width: parent.width
            height: 48

            // the media popup's tile
            Rectangle {
                id: tile
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44
                radius: 8
                color: Qt.alpha(Theme.fg, 0.06)

                Txt {
                    anchors.centerIn: parent
                    text: root.audio?.muted ? "󰝟"
                        : root.pct(root.audio) < 25 ? "󰕿"
                        : root.pct(root.audio) < 65 ? "󰖀" : "󰕾"
                    color: root.audio?.muted ? Qt.alpha(Theme.fg, 0.45) : Theme.green
                    font.pixelSize: 22
                }
            }

            Column {
                anchors.left: tile.right
                anchors.leftMargin: 12
                anchors.right: outMute.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Txt {
                    text: "Volume"
                    font.pixelSize: 13
                    font.bold: true
                }
                Txt {
                    width: parent.width
                    text: (root.current ? root.label(root.current) : "no output")
                        + " · " + (root.audio?.muted ? "muted" : root.pct(root.audio) + "%")
                    color: Qt.alpha(Theme.fg, 0.55)
                    elide: Text.ElideRight
                }
            }

            MutePill {
                id: outMute
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                active: root.audio?.muted ?? false
                onClicked: if (root.audio) root.audio.muted = !root.audio.muted
            }
        }

        // --- Output ---
        SectionLabel { text: "Output" }

        TweakSlider {
            label: "volume"
            from: 0; to: 100
            value: root.pct(root.audio)
            suffix: "%"
            applyFn: v => {
                if (!root.audio) return
                root.audio.muted = false
                root.audio.volume = v / 100
            }
            persistFn: v => {}   // PipeWire remembers
        }

        Repeater {
            model: root.sinks
            DeviceRow {
                chosen: root.current
                glyph: "󰓃"
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
        }

        Txt {
            visible: root.sinks.length === 0
            text: "no outputs"
            color: Qt.alpha(Theme.fg, 0.5)
            font.pixelSize: 12
            leftPadding: 10
        }

        // --- Profile: per card with a choice; the outputs above follow ---
        Repeater {
            model: root.cards
            Column {
                id: cardCol
                required property var modelData
                width: parent.width
                spacing: 2
                SectionLabel { text: root.cards.length > 1 ? "Profile · " + cardCol.modelData.desc : "Profile" }
                Repeater {
                    model: cardCol.modelData.rows
                    ListRow {
                        required property var modelData
                        height: 28
                        glyphSize: 13
                        glyph: "󰋋"
                        check: true
                        active: modelData.active
                        text: modelData.label
                        onClicked: root.setProfile(modelData.card, modelData.profile)
                    }
                }
            }
        }

        // --- Input: only with a microphone ---
        Item {
            visible: root.sources.length > 0
            width: parent.width
            height: 30

            SectionLabel {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                topPadding: 0
                text: "Input"
            }
            MutePill {
                visible: root.micAudio !== null
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                active: root.micAudio?.muted ?? false
                onClicked: if (root.micAudio) root.micAudio.muted = !root.micAudio.muted
            }
        }

        TweakSlider {
            visible: root.micAudio !== null
            label: "microphone"
            from: 0; to: 100
            value: root.pct(root.micAudio)
            suffix: "%"
            applyFn: v => {
                if (!root.micAudio) return
                root.micAudio.volume = v / 100
            }
            persistFn: v => {}
        }

        // live level: square root so speech fills a useful part of the
        // bar; red near clipping
        Rectangle {
            visible: root.micAudio !== null
            width: parent.width - 8
            anchors.horizontalCenter: parent.horizontalCenter
            height: 4
            radius: 2
            color: Qt.alpha(Theme.fg, 0.1)

            Rectangle {
                readonly property real level: root.micAudio?.muted ? 0 : Math.min(1, Math.sqrt(meter.peak))
                width: parent.width * level
                height: parent.height
                radius: 2
                color: level > 0.95 ? Theme.red : Theme.accent
                Behavior on width { NumberAnimation { duration: 80 } }
            }
        }

        Repeater {
            model: root.sources
            DeviceRow {
                chosen: root.mic
                glyph: "󰍬"
                onClicked: Pipewire.preferredDefaultAudioSource = modelData
            }
        }

        // --- Apps: each thing playing, its own level ---
        SectionLabel {
            visible: root.apps.length > 0
            text: "Apps"
        }

        Repeater {
            model: root.apps

            TweakSlider {
                id: appSlider
                required property var modelData
                label: modelData.name
                from: 0; to: 100
                value: root.pct(modelData.nodes[0].audio)
                suffix: "%"
                applyFn: v => {
                    for (const n of appSlider.modelData.nodes)
                        if (n.audio) n.audio.volume = v / 100
                }
                persistFn: v => {}
            }
        }

        Rectangle { width: parent.width - 8; anchors.horizontalCenter: parent.horizontalCenter; height: 1; color: Qt.alpha(Theme.fg, 0.15) }

        ListRow {
            height: 34
            glyphSize: 15
            fontSize: 13
            glyphWidth: 0
            glyph: "󰕾"
            text: "Mixer (pavucontrol)"
            onClicked: {
                root.visible = false
                Quickshell.execDetached(["pavucontrol"])
            }
        }
    }
}
