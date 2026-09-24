// ConnectionStatus.qml
// LibrePods HiiT: explains what the app is doing while the AirPods are not connected,
// and what the user can do about it.
import QtQuick

Column {
    id: root

    property string connectionState: "searching" // off, searching, paired, nearby, connecting or failed
    property string deviceName: ""
    property bool nearbyDetection: false // experimental "nearby" detection is on

    signal retryRequested()
    signal connectRequested()
    signal powerOnRequested()

    readonly property bool busy: connectionState === "searching" || connectionState === "connecting"

    spacing: 12

    Item {
        width: parent.width
        height: 48

        Icon {
            anchors.centerIn: parent
            visible: !root.busy
            size: 40
            name: root.connectionState === "off" ? "bluetooth-off"
                : root.connectionState === "nearby" || root.connectionState === "paired" ? "bud"
                : "circle-alert"
            color: root.connectionState === "failed" ? Theme.danger
                 : root.connectionState === "nearby" || root.connectionState === "paired" ? Theme.foreground
                 : Theme.mutedForeground
        }

        Icon {
            id: spinner
            anchors.centerIn: parent
            visible: root.busy
            size: 40
            name: "loader-circle"
            color: Theme.mutedForeground

            RotationAnimator on rotation {
                running: spinner.visible
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }
        }
    }

    Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: Theme.foreground
        text: {
            switch (root.connectionState) {
            case "off": return qsTr("Bluetooth is off");
            case "connecting": return root.deviceName !== "" ? qsTr("Connecting to %1…").arg(root.deviceName)
                                                             : qsTr("Connecting to your AirPods…");
            case "failed": return qsTr("Couldn't connect to your AirPods");
            case "paired": return root.deviceName !== "" ? root.deviceName : qsTr("Your AirPods");
            case "nearby": return root.deviceName !== "" ? qsTr("%1 is nearby").arg(root.deviceName)
                                                         : qsTr("Your AirPods are nearby");
            default: return qsTr("Looking for your AirPods…");
            }
        }
    }

    Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        lineHeight: 1.3
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: Theme.mutedForeground
        visible: text !== ""
        text: {
            switch (root.connectionState) {
            case "off": return qsTr("Turn on Bluetooth to control your AirPods.");
            case "connecting": return "";
            case "failed": return qsTr("Make sure they are out of the case, close to this computer and connected in your system's Bluetooth settings.");
            case "paired": return qsTr("Paired but not connected. If this computer was the last one used, they connect on their own when taken out of the case. If they are in use on another device, such as an iPhone, click Connect.");
            case "nearby": return qsTr("Connect to use them on this computer. If they are in use on another device, they may move to this one.");
            default: return root.nearbyDetection
                     ? qsTr("Open the AirPods case near this computer to find them. They must already be paired in your system's Bluetooth settings.")
                     : qsTr("Connect the AirPods in your system's Bluetooth settings and LibrePods will pick them up.");
            }
        }
    }

    UiButton {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.connectionState === "off" || root.connectionState === "failed"
                 || root.connectionState === "nearby" || root.connectionState === "paired"
        variant: "default"
        iconName: root.connectionState === "failed" ? "refresh-cw" : "bluetooth-connected"
        text: root.connectionState === "off" ? qsTr("Turn on Bluetooth")
            : root.connectionState === "nearby" || root.connectionState === "paired" ? qsTr("Connect")
            : qsTr("Try again")
        onClicked: {
            if (root.connectionState === "off")
                root.powerOnRequested();
            else if (root.connectionState === "nearby" || root.connectionState === "paired")
                root.connectRequested();
            else
                root.retryRequested();
        }
    }
}
