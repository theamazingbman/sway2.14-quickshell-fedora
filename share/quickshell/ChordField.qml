import QtQuick

// A key chord to edit: the text ("super+shift+b"), a Record button that
// takes the next chord from the keyboard, and the chord as keycaps.
// Recording: the next chord typed lands in the field. A bare Escape
// stops without recording (Escape with modifiers records). Mango keeps
// its own binds while recording, so a chord that is already bound acts
// instead of arriving; type that one in the field.
Row {
    id: root
    property alias text: field.text
    property alias input: field.input
    property bool recording: false
    signal accepted()
    signal escaped()
    spacing: 8

    // "super+shift+b" -> ["super+shift", "b"]
    function split(s) {
        const parts = s.trim().split("+").map(x => x.trim()).filter(x => x !== "")
        if (!parts.length)
            return ["none", ""]
        const key = parts.pop()
        return [parts.length ? parts.join("+").toLowerCase() : "none", key]
    }
    function start() {
        recording = true
        recorder.forceActiveFocus()
    }
    function stop() {
        if (!recording)
            return
        recording = false
        field.input.forceActiveFocus()
    }
    // the X keysym name for a Qt key event, or null for a modifier alone
    function keysymOf(e) {
        const k = e.key
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k).toLowerCase()
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k)
        if (k >= Qt.Key_F1 && k <= Qt.Key_F35) return "F" + (k - Qt.Key_F1 + 1)
        const named = [
            [Qt.Key_Return, "Return"], [Qt.Key_Enter, "KP_Enter"], [Qt.Key_Space, "space"],
            [Qt.Key_Tab, "Tab"], [Qt.Key_Backtab, "Tab"], [Qt.Key_Escape, "Escape"],
            [Qt.Key_Left, "Left"], [Qt.Key_Right, "Right"], [Qt.Key_Up, "Up"], [Qt.Key_Down, "Down"],
            [Qt.Key_Home, "Home"], [Qt.Key_End, "End"], [Qt.Key_PageUp, "Prior"], [Qt.Key_PageDown, "Next"],
            [Qt.Key_Insert, "Insert"], [Qt.Key_Delete, "Delete"], [Qt.Key_Backspace, "BackSpace"],
            [Qt.Key_Print, "Print"], [Qt.Key_Pause, "Pause"], [Qt.Key_Menu, "Menu"],
            [Qt.Key_QuoteLeft, "grave"], [Qt.Key_AsciiTilde, "grave"],
            [Qt.Key_Minus, "minus"], [Qt.Key_Underscore, "minus"],
            [Qt.Key_Equal, "equal"], [Qt.Key_Plus, "equal"],
            [Qt.Key_Comma, "comma"], [Qt.Key_Less, "comma"],
            [Qt.Key_Period, "period"], [Qt.Key_Greater, "period"],
            [Qt.Key_Slash, "slash"], [Qt.Key_Question, "slash"],
            [Qt.Key_Apostrophe, "apostrophe"], [Qt.Key_QuoteDbl, "apostrophe"],
            [Qt.Key_Semicolon, "semicolon"], [Qt.Key_Colon, "semicolon"],
            [Qt.Key_BracketLeft, "bracketleft"], [Qt.Key_BraceLeft, "bracketleft"],
            [Qt.Key_BracketRight, "bracketright"], [Qt.Key_BraceRight, "bracketright"],
            [Qt.Key_Backslash, "backslash"], [Qt.Key_Bar, "backslash"],
            // shifted digits on a US layout
            [Qt.Key_Exclam, "1"], [Qt.Key_At, "2"], [Qt.Key_NumberSign, "3"], [Qt.Key_Dollar, "4"],
            [Qt.Key_Percent, "5"], [Qt.Key_AsciiCircum, "6"], [Qt.Key_Ampersand, "7"],
            [Qt.Key_Asterisk, "8"], [Qt.Key_ParenLeft, "9"], [Qt.Key_ParenRight, "0"],
            [Qt.Key_VolumeUp, "XF86AudioRaiseVolume"], [Qt.Key_VolumeDown, "XF86AudioLowerVolume"],
            [Qt.Key_VolumeMute, "XF86AudioMute"], [Qt.Key_MicMute, "XF86AudioMicMute"],
            [Qt.Key_MonBrightnessUp, "XF86MonBrightnessUp"], [Qt.Key_MonBrightnessDown, "XF86MonBrightnessDown"],
            [Qt.Key_MediaPlay, "XF86AudioPlay"], [Qt.Key_MediaTogglePlayPause, "XF86AudioPlay"],
            [Qt.Key_MediaNext, "XF86AudioNext"], [Qt.Key_MediaPrevious, "XF86AudioPrev"],
            [Qt.Key_MediaStop, "XF86AudioStop"]
        ]
        for (const n of named)
            if (n[0] === k) return n[1]
        return null
    }

    Item {
        id: recorder
        Keys.onPressed: e => {
            if (!root.recording)
                return
            e.accepted = true
            const bare = (e.modifiers & ~Qt.KeypadModifier) === 0
            if (e.key === Qt.Key_Escape && bare) { root.stop(); return }
            const k = root.keysymOf(e)
            if (!k)
                return      // a modifier on its own: keep waiting
            const mods = []
            if (e.modifiers & Qt.MetaModifier) mods.push("super")
            if (e.modifiers & Qt.ControlModifier) mods.push("ctrl")
            if (e.modifiers & Qt.AltModifier) mods.push("alt")
            if (e.modifiers & Qt.ShiftModifier) mods.push("shift")
            field.text = mods.concat([k]).join("+")
            root.stop()
        }
    }

    EditField {
        id: field
        width: 240
        placeholder: "super+shift+b"
        onAccepted: root.accepted()
        onEscaped: root.escaped()
    }
    EditButton {
        anchors.verticalCenter: parent.verticalCenter
        label: root.recording ? "press a chord… (esc stops)" : "󰌌 Record"
        primary: root.recording
        onClicked: root.recording ? root.stop() : root.start()
    }
    // the chord as keycaps, as the list will show it
    Flow {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3
        Repeater {
            model: {
                const ck = root.split(field.text)
                const parts = ck[0] === "none" ? [] : ck[0].split("+")
                if (ck[1] !== "") parts.push(ck[1])
                return parts.map(p => p.length === 1 ? p.toUpperCase()
                    : p.charAt(0).toUpperCase() + p.slice(1))
            }
            Keycap { required property string modelData; text: modelData }
        }
    }
}
