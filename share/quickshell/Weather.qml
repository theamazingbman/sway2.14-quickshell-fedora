import QtQuick

// Weather: condition glyph + temperature (WeatherData, one fetch for every
// output); click for the 3-day forecast card, right click jumps to its
// location field. Hidden until the first successful fetch.
BarModule {
    id: root

    visible: WeatherData.temp !== ""
    icon: WeatherData.glyphFor(WeatherData.code)
    iconColor: Theme.yellow
    label: WeatherData.temp + "°"

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            forecast.openSettings()
        else
            forecast.visible = !forecast.visible
    }

    WeatherPopup {
        id: forecast
        anchorItem: root
    }
}
