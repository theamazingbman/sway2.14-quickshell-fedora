import QtQuick

// A popup's section heading. caps: the smaller spaced uppercase header
// of a settings list group.
Txt {
    property bool caps: false
    color: Theme.accent
    font.pixelSize: caps ? 11 : 12
    font.bold: true
    font.capitalization: caps ? Font.AllUppercase : Font.MixedCase
    font.letterSpacing: caps ? 1 : 0
    topPadding: 6
    leftPadding: caps ? 6 : 0
}
