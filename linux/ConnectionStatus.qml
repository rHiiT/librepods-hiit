// ConnectionStatus.qml
// LibrePods HiiT: explains what the app is doing while the AirPods are not connected,
// and what the user can do about it.
import QtQuick
import QtQuick.Layouts

Column {
    id: root

    property string connectionState: "unpaired" // off, unpaired, paired, nearby, connecting or failed
    property string deviceName: ""
    property bool canOpenBluetoothSettings: false

    signal retryRequested()
    signal connectRequested()
    signal powerOnRequested()
    signal bluetoothSettingsRequested()

    readonly property bool busy: connectionState === "connecting"
    readonly property bool knownDevice: connectionState === "paired" || connectionState === "nearby"

    spacing: 12

    Item {
        width: parent.width
        height: 48

        // The case is where pairing and reconnecting start, so it is the main symbol
        Icon {
            anchors.centerIn: parent
            visible: !root.busy
            size: 40
            name: root.connectionState === "off" ? "bluetooth-off"
                : root.knownDevice || root.connectionState === "unpaired" ? "case"
                : "circle-alert"
            color: root.connectionState === "failed" ? Theme.danger
                 : root.knownDevice ? Theme.foreground
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
            default: return qsTr("No AirPods paired");
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
            case "failed": return qsTr("Check that they are connected in the system's Bluetooth settings.");
            case "paired": return qsTr("If they don't connect when taken out of the case, click Connect.");
            case "nearby": return qsTr("Connect to use them on this computer. If they are in use on another device, they may move to this one.");
            default: return "";
            }
        }
    }

    // First-time pairing: short numbered steps instead of a paragraph
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.connectionState === "unpaired"
        spacing: 8

        Repeater {
            model: [
                qsTr("Open the case with the AirPods inside."),
                qsTr("Hold the button on the back until the light flashes white."),
                qsTr("Pair them in the system's Bluetooth settings.")
            ]

            delegate: RowLayout {
                id: step
                required property int index
                required property string modelData
                spacing: 8

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: Theme.muted

                    Text {
                        anchors.centerIn: parent
                        text: step.index + 1
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        color: Theme.foreground
                    }
                }

                Text {
                    Layout.maximumWidth: root.width - 60
                    text: step.modelData
                    wrapMode: Text.WordWrap
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: Theme.mutedForeground
                }
            }
        }
    }

    UiButton {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.connectionState === "off" || root.connectionState === "failed" || root.knownDevice
                 || (root.connectionState === "unpaired" && root.canOpenBluetoothSettings)
        variant: "default"
        iconName: root.connectionState === "failed" ? "refresh-cw"
                : root.connectionState === "unpaired" ? "settings"
                : "bluetooth-connected"
        text: root.connectionState === "off" ? qsTr("Turn on Bluetooth")
            : root.knownDevice ? qsTr("Connect")
            : root.connectionState === "unpaired" ? qsTr("Open Bluetooth settings")
            : qsTr("Try again")
        onClicked: {
            if (root.connectionState === "off")
                root.powerOnRequested();
            else if (root.knownDevice)
                root.connectRequested();
            else if (root.connectionState === "unpaired")
                root.bluetoothSettingsRequested();
            else
                root.retryRequested();
        }
    }
}
