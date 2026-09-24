// UiLabel.qml
// LibrePods HiiT: text in the theme font; `tone` picks the color role.
import QtQuick

Text {
    property string tone: "default" // default, muted or danger

    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    color: tone === "muted" ? Theme.mutedForeground : tone === "danger" ? Theme.danger : Theme.foreground
    wrapMode: Text.WordWrap
}
