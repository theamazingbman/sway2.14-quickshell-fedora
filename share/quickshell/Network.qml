import QtQuick
import Quickshell

// Active connection indicator. The icon shows the transport (Wi-Fi bars
// follow the signal, ethernet, VPN shield) and follows `nmcli monitor`.
// "sign in" shows when the network wants a login page first, "no internet"
// when it doesn't reach the internet; both need NetworkManager's
// connectivity check. Click opens the login page while "sign in" shows,
// the network app otherwise; right click opens nm-connection-editor.
BarModule {
    id: root

    readonly property color stateColor: !Sys.online || Sys.noInternet ? Theme.red
                                      : Sys.signInNeeded ? Theme.accent
                                      : Sys.vpnOn ? Theme.green : Theme.cyan

    icon: Sys.netIcon
    iconColor: stateColor
    label: Sys.signInNeeded ? "sign in" : Sys.noInternet ? "no internet" : ""
    labelColor: stateColor

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Quickshell.execDetached(["nm-connection-editor"])
        else if (Sys.signInNeeded)
            // any plain-http page gets redirected to the login page; NM's own
            // check URL is the one it already saw intercepted
            Quickshell.execDetached(["xdg-open", Sys.checkUri || "http://neverssl.com"])
        else
            Quickshell.execDetached([Theme.shareDir + "/scripts/network"])
    }
}
