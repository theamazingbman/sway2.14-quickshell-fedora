import QtQuick
import Quickshell
import Quickshell.Io

// Weather popup: a three-day forecast from WeatherData, then a location
// field (Enter pins it, "auto" unpins it) and units. They write the
// weather-location and weather-units state files WeatherData watches. Right-click the module to open with the field
// focused. "radar" swaps the forecast for the last hour of rain (RadarView).
Popout {
    id: root
    ipcNames: ["weather"]
    function ipc(fn, arg) {
        if (fn === "toggle") root.visible = !root.visible
        else if (fn === "radar") { root.visible = true; root.radar = true }
    }

    readonly property string condition: WeatherData.condition
    readonly property string feels: WeatherData.feels
    readonly property string wind: WeatherData.wind
    readonly property string place: WeatherData.place
    readonly property var days: WeatherData.days
    readonly property bool failed: WeatherData.failed
    readonly property real lat: WeatherData.lat
    readonly property real lon: WeatherData.lon
    property bool radar: false

    // the saved settings ("" = auto)
    readonly property string location: WeatherData.location
    readonly property string units: WeatherData.unitsOverride

    readonly property bool localeF: Qt.locale().measurementSystem !== Locale.MetricSystem

    cardWidth: radar ? 420 : 300
    cardHeight: radar ? 380 : 268

    onVisibleChanged: {
        if (visible)
            field.text = location
        else
            radar = false
    }
    onLocationChanged: if (!field.activeFocus) field.text = location

    function openSettings() {
        visible = true
        // after Popout's own focus grab on open
        Qt.callLater(() => {
            field.forceActiveFocus()
            field.selectAll()
        })
    }

    // write a settings state file, or remove it for "" (auto)
    function save(name, value) {
        if (value === "")
            Quickshell.execDetached(["rm", "-f", Theme.stateDir + "/" + name])
        else
            Theme.writeState(name, value)
    }

    function saveLocation() {
        const v = field.text.trim()
        field.text = v
        if (v !== location)
            save("weather-location", v)
    }

    // forecast ⇄ radar, top right (radar needs a located forecast)
    Btn {
        id: radarBtn
        visible: root.lat !== 0 || root.lon !== 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: -4
        active: root.radar
        text: active ? "󰖎  forecast" : "󰖎  radar"
        height: 22
        radius: 7
        padding: 16
        fontSize: 10
        bold: false
        onClicked: root.radar = !root.radar
    }

    // where the forecast is for (shows when a VPN fools wttr.in's
    // geolocation), or that the fetch failed
    Txt {
        id: placeLine
        anchors.left: parent.left
        anchors.right: radarBtn.visible ? radarBtn.left : parent.right
        anchors.rightMargin: radarBtn.visible ? 8 : 0
        anchors.top: parent.top
        visible: root.place !== "" || root.failed
        text: root.failed
            ? "󰅙 couldn't get the weather" + (root.location !== "" ? " for \"" + root.location + "\"" : "")
            : "󰍎 " + root.place
        color: root.failed ? Theme.red : Qt.alpha(Theme.fg, 0.5)
        font.pixelSize: 10
        elide: Text.ElideRight
    }

    // current condition · feels like · wind
    Txt {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: placeLine.visible ? placeLine.bottom : parent.top
        anchors.topMargin: placeLine.visible ? 4 : 0
        text: root.condition
            + (root.feels !== "" ? "  ·  feels " + root.feels + "°" : "")
            + (root.wind !== "" ? "  ·  󰖝 " + root.wind : "")
        font.pixelSize: 12
        font.bold: true
        elide: Text.ElideRight
    }

    RadarView {
        visible: root.radar
        active: root.radar && root.visible
        lat: root.lat
        lon: root.lon
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
    }

    Row {
        visible: !root.radar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.topMargin: 12
        anchors.bottom: settings.top
        anchors.bottomMargin: 12

        Repeater {
            model: root.days

            Column {
                id: day
                required property var modelData
                width: parent.width / Math.max(root.days.length, 1)
                spacing: 5

                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: day.modelData.label
                    color: Qt.alpha(Theme.fg, 0.55)
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: day.modelData.glyph
                    color: Theme.yellow
                    font.pixelSize: 22
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: day.modelData.hi + "° / " + day.modelData.lo + "°"
                    font.pixelSize: 12
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: day.modelData.rain >= 30
                    text: "󰖌 " + day.modelData.rain + "%"
                    color: Theme.cyan
                    font.pixelSize: 10
                }
            }
        }
    }

    Column {
        id: settings
        visible: !root.radar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 8

        Rectangle { width: parent.width; height: 1; color: Qt.alpha(Theme.fg, 0.15) }

        // location: type + Enter pins it; "auto" goes back to by-IP
        Row {
            width: parent.width
            spacing: 6

            Rectangle {
                width: parent.width - (autoBtn.visible ? autoBtn.width + parent.spacing : 0)
                height: 30
                radius: 8
                color: Qt.alpha(Theme.fg, 0.06)
                border.width: 1
                border.color: field.activeFocus ? Qt.alpha(Theme.accent, 0.5) : "transparent"

                Txt {
                    id: pin
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍎"
                    color: Theme.accent
                    font.pixelSize: 13
                }

                // under the field, so a click on the text still places the cursor
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: field.forceActiveFocus()
                }

                TextInput {
                    id: field
                    anchors.left: pin.right
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fg
                    selectionColor: Qt.alpha(Theme.accent, 0.4)
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    selectByMouse: true
                    clip: true
                    onAccepted: {
                        root.saveLocation()
                        focus = false
                    }
                    // Escape drops an unsaved edit first, then closes (Popout)
                    Keys.onEscapePressed: event => {
                        if (text !== root.location)
                            text = root.location
                        else
                            event.accepted = false
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: field.text === ""
                        text: "auto (by IP) · type a city or zip"
                        color: Qt.alpha(Theme.fg, 0.35)
                        font: field.font
                    }
                }
            }

            Btn {
                id: autoBtn
                visible: root.location !== ""
                text: "auto"
                height: 30
                padding: 16
                fadeMs: 0
                onClicked: {
                    field.text = ""
                    root.save("weather-location", "")
                }
            }
        }

        // units: auto (from the locale) / °F / °C
        Row {
            width: parent.width
            spacing: 6

            Repeater {
                model: [
                    { value: "", label: "auto · " + (root.localeF ? "°F" : "°C") },
                    { value: "f", label: "°F" },
                    { value: "c", label: "°C" }
                ]

                Btn {
                    required property var modelData
                    active: root.units === modelData.value
                    text: modelData.label
                    width: (parent.width - 2 * parent.spacing) / 3
                    height: 26
                    onClicked: root.save("weather-units", modelData.value)
                }
            }
        }
    }
}
