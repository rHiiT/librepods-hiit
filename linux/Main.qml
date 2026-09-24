// Main.qml
// Modified by LibrePods HiiT: controls rebuilt on the Ui* component kit, Departure Mono
// font, Lucide icons, a connection badge that does not rely on color alone, a status
// panel for every non-connected state; settings moved to SettingsPage.qml; frameless
// window with its own title bar (TitleBar.qml).
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ApplicationWindow {
    id: mainWindow
    visible: !airPodsTrayApp.hideOnStart
    width: 440
    height: 540
    minimumWidth: 400
    minimumHeight: 420
    flags: Qt.Window | Qt.FramelessWindowHint
    title: "LibrePods HiiT Edition"
    objectName: "mainWindowObject"
    color: Theme.background
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    onClosing: mainWindow.visible = false

    UiToast {
        id: appToast
    }

    function reopen(pageToLoad) {
        if (pageToLoad == "settings")
        {
            if (stackView.depth == 1)
            {
                stackView.push(settingsPage)
            }
        }
        else
        {
            if (stackView.depth > 1)
            {
                stackView.pop()
            }
        }

        if (!mainWindow.visible) {
            mainWindow.visible = true
        }
        raise()
        requestActivate()
    }

    // Mouse area for handling back/forward navigation
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.BackButton && stackView.depth > 1) {
                stackView.pop()
            } else if (mouse.button === Qt.ForwardButton) {
                console.log("Forward button pressed")
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            Layout.fillWidth: true
            showSettings: stackView.depth === 1
            onSettingsRequested: stackView.push(settingsPage)
        }

        StackView {
            id: stackView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            initialItem: mainPage
        }
    }

    // Window outline: without the system frame the window needs its own edge
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: Theme.border
    }

    WindowResizeHandles {}

    Component {
        id: mainPage
        ScrollView {
            id: mainScroll
            contentWidth: availableWidth

            ColumnLayout {
                x: 20
                y: 20
                width: mainScroll.availableWidth - 40
                spacing: 20

                UiBadge {
                    maximumWidth: parent.width
                    readonly property string connectionState: airPodsTrayApp.connectionState
                    text: {
                        switch (connectionState) {
                        case "connected": return airPodsTrayApp.deviceInfo.deviceName !== ""
                                                 ? qsTr("Connected · %1").arg(airPodsTrayApp.deviceInfo.deviceName)
                                                 : qsTr("Connected");
                        case "connecting": return qsTr("Connecting");
                        case "off": return qsTr("Bluetooth off");
                        case "failed": return qsTr("Not connected");
                        case "nearby": return qsTr("Nearby");
                        default: return qsTr("Searching");
                        }
                    }
                    iconName: connectionState === "connected" ? "bluetooth-connected"
                            : connectionState === "off" || connectionState === "failed" ? "bluetooth-off"
                            : "bluetooth-searching"
                    tone: connectionState === "connected" ? Theme.success
                        : connectionState === "off" || connectionState === "failed" ? Theme.danger
                        : Theme.mutedForeground
                }

                ConnectionStatus {
                    Layout.fillWidth: true
                    Layout.topMargin: 32
                    visible: !airPodsTrayApp.airpodsConnected
                    connectionState: airPodsTrayApp.connectionState === "connected" ? "connecting" : airPodsTrayApp.connectionState
                    deviceName: airPodsTrayApp.deviceInfo.deviceName !== "" ? airPodsTrayApp.deviceInfo.deviceName
                                                                            : airPodsTrayApp.lastDeviceName
                    onRetryRequested: airPodsTrayApp.retryConnection()
                    nearbyDetection: airPodsTrayApp.nearbyConnectEnabled
                    onConnectRequested: airPodsTrayApp.connectNearby()
                    onPowerOnRequested: airPodsTrayApp.powerOnBluetooth()
                }

                // Battery Indicator Row
                Row {
                    Layout.alignment: Qt.AlignHCenter
                    visible: airPodsTrayApp.airpodsConnected
                    spacing: 24

                    PodColumn {
                        visible: airPodsTrayApp.deviceInfo.battery.leftPodAvailable
                        inEar: airPodsTrayApp.deviceInfo.leftPodInEar
                        illustration: airPodsTrayApp.deviceInfo.podIcon
                        batteryLevel: airPodsTrayApp.deviceInfo.battery.leftPodLevel
                        isCharging: airPodsTrayApp.deviceInfo.battery.leftPodCharging
                        indicator: "L"
                    }

                    PodColumn {
                        visible: airPodsTrayApp.deviceInfo.battery.rightPodAvailable
                        inEar: airPodsTrayApp.deviceInfo.rightPodInEar
                        illustration: airPodsTrayApp.deviceInfo.podIcon
                        batteryLevel: airPodsTrayApp.deviceInfo.battery.rightPodLevel
                        isCharging: airPodsTrayApp.deviceInfo.battery.rightPodCharging
                        indicator: "R"
                    }

                    PodColumn {
                        visible: airPodsTrayApp.deviceInfo.battery.caseAvailable
                        inEar: true
                        illustration: airPodsTrayApp.deviceInfo.caseIcon
                        batteryLevel: airPodsTrayApp.deviceInfo.battery.caseLevel
                        isCharging: airPodsTrayApp.deviceInfo.battery.caseCharging
                        lastKnown: airPodsTrayApp.deviceInfo.battery.caseLastKnown
                    }

                    PodColumn {
                        visible: airPodsTrayApp.deviceInfo.battery.headsetAvailable
                        inEar: true
                        illustration: airPodsTrayApp.deviceInfo.podIcon
                        batteryLevel: airPodsTrayApp.deviceInfo.battery.headsetLevel
                        isCharging: airPodsTrayApp.deviceInfo.battery.headsetCharging
                    }
                }

                SegmentedControl {
                    Layout.fillWidth: true
                    model: [qsTr("Off"), qsTr("Noise Cancellation"), qsTr("Transparency"), qsTr("Adaptive")]
                    icons: ["circle-off", "headphone-off", "ear", "audio-lines"]
                    currentIndex: airPodsTrayApp.deviceInfo.noiseControlMode
                    onActivated: (index) => airPodsTrayApp.setNoiseControlModeInt(index)
                    visible: airPodsTrayApp.airpodsConnected
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: airPodsTrayApp.airpodsConnected && airPodsTrayApp.deviceInfo.adaptiveModeActive
                    spacing: 8

                    Text {
                        text: qsTr("Adaptive Noise Level: ") + adaptiveSlider.value
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        color: Theme.foreground
                    }

                    UiSlider {
                        id: adaptiveSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        stepSize: 1
                        value: airPodsTrayApp.deviceInfo.adaptiveNoiseLevel

                        Timer {
                            id: debounceTimer
                            interval: 500
                            onTriggered: if (!adaptiveSlider.pressed) airPodsTrayApp.setAdaptiveNoiseLevel(adaptiveSlider.value)
                        }

                        onPressedChanged: if (!pressed) airPodsTrayApp.setAdaptiveNoiseLevel(value)
                        onValueChanged: if (pressed) debounceTimer.restart()
                    }
                }

                UiSwitch {
                    Layout.fillWidth: true
                    visible: airPodsTrayApp.airpodsConnected
                    iconName: "speech"
                    text: qsTr("Conversational Awareness")
                    checked: airPodsTrayApp.deviceInfo.conversationalAwareness
                    onToggled: airPodsTrayApp.setConversationalAwareness(checked)
                }

                UiSwitch {
                    Layout.fillWidth: true
                    visible: airPodsTrayApp.airpodsConnected
                    iconName: "ear"
                    text: qsTr("Hearing Aid")
                    checked: airPodsTrayApp.deviceInfo.hearingAidEnabled
                    onToggled: airPodsTrayApp.setHearingAidEnabled(checked)
                }

                Item {
                    implicitHeight: 20
                }
            }
        }
    }

    Component {
        id: settingsPage
        SettingsPage {
            toast: appToast
            onBackRequested: stackView.pop()
        }
    }
}
