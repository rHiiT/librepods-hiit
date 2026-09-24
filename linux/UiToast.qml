// UiToast.qml
// LibrePods HiiT: short confirmation message at the bottom of the window (shadcn/ui "Sonner" style).
import QtQuick
import QtQuick.Controls.Basic

Popup {
    id: root

    property string text: ""
    property bool error: false

    function show(message, isError) {
        text = message;
        error = isError === true;
        open();
        hideTimer.restart();
    }

    x: (parent.width - width) / 2
    y: parent.height - height - 20
    width: Math.min(implicitWidth, parent.width - 40)
    padding: 12
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    focus: false

    Timer {
        id: hideTimer
        interval: root.error ? 6000 : 3000
        onTriggered: root.close()
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animationDuration }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animationDuration }
    }

    contentItem: Row {
        spacing: 10

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.error ? "circle-alert" : "circle-check"
            color: root.error ? Theme.danger : Theme.success
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.parent.width - 40 - 2 * root.padding - Theme.iconSize - parent.spacing)
            text: root.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Theme.foreground
            wrapMode: Text.WordWrap
            Accessible.role: Accessible.AlertMessage
        }
    }

    background: Rectangle {
        radius: Theme.radius
        color: Theme.background
        border.width: 1
        border.color: Theme.border
    }
}
