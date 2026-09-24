// Main.qml
// Modified by LibrePods HiiT: controls rebuilt on the Ui* component kit, Departure Mono
// font, Lucide icons, a connection badge that does not rely on color alone, a status
// panel for every non-connected state, and feedback for rename and phone address.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ApplicationWindow {
    id: mainWindow
    visible: !airPodsTrayApp.hideOnStart
    width: 440
    height: 480
    minimumWidth: 400
    minimumHeight: 380
    title: "LibrePods"
    objectName: "mainWindowObject"
    color: Theme.background
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize

    onClosing: mainWindow.visible = false

    UiToast {
        id: toast
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

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: mainPage
    }

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

                // Header: device name, connection status and settings
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: airPodsTrayApp.airpodsConnected && airPodsTrayApp.deviceInfo.deviceName !== ""
                              ? airPodsTrayApp.deviceInfo.deviceName : "LibrePods"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.foreground
                        elide: Text.ElideRight
                    }

                    UiButton {
                        variant: "ghost"
                        iconName: "settings"
                        toolTipText: qsTr("Settings")
                        onClicked: stackView.push(settingsPage)
                    }
                }

                UiBadge {
                    readonly property string connectionState: airPodsTrayApp.connectionState
                    text: {
                        switch (connectionState) {
                        case "connected": return qsTr("Connected");
                        case "connecting": return qsTr("Connecting");
                        case "off": return qsTr("Bluetooth off");
                        case "failed": return qsTr("Not connected");
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
                    deviceName: airPodsTrayApp.deviceInfo.deviceName
                    onRetryRequested: airPodsTrayApp.retryConnection()
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
        Page {
            id: settingsPageItem
            title: qsTr("Settings")
            background: Rectangle { color: Theme.background }

            Shortcut {
                sequences: [StandardKey.Back, "Esc"]
                onActivated: stackView.pop()
            }

            header: Rectangle {
                implicitHeight: 56
                color: Theme.background

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 20
                    spacing: 8

                    UiButton {
                        variant: "ghost"
                        iconName: "arrow-left"
                        toolTipText: qsTr("Back")
                        onClicked: stackView.pop()
                    }

                    Text {
                        Layout.fillWidth: true
                        text: settingsPageItem.title
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.foreground
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.border
                }
            }

            ScrollView {
                id: settingsScroll
                anchors.fill: parent
                contentWidth: availableWidth

                ColumnLayout {
                    width: settingsScroll.availableWidth
                    spacing: 20

                    Item { implicitHeight: 4 }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20
                        Layout.rightMargin: 20
                        spacing: 8 // Small gap between label and ComboBox

                        Text {
                            text: qsTr("Pause Behavior When Removing AirPods:")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: Theme.foreground
                        }

                        UiSelect {
                            Layout.fillWidth: true
                            model: [qsTr("One Removed"), qsTr("Both Removed"), qsTr("Never")]
                            currentIndex: airPodsTrayApp.earDetectionBehavior
                            onActivated: airPodsTrayApp.earDetectionBehavior = currentIndex
                        }
                    }

                    UiSwitch {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20
                        Layout.rightMargin: 20
                        iconName: "smartphone"
                        text: qsTr("Cross-Device Connectivity with Android")
                        checked: airPodsTrayApp.crossDeviceEnabled
                        onToggled: airPodsTrayApp.setCrossDeviceEnabled(checked)
                    }

                    UiSwitch {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20
                        Layout.rightMargin: 20
                        iconName: "power"
                        text: qsTr("Auto-Start on Login")
                        checked: airPodsTrayApp.autoStartManager.autoStartEnabled
                        onToggled: airPodsTrayApp.autoStartManager.autoStartEnabled = checked
                    }

                    UiSwitch {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20
                        Layout.rightMargin: 20
                        iconName: "bell"
                        text: qsTr("Enable System Notifications")
                        checked: airPodsTrayApp.notificationsEnabled
                        onToggled: airPodsTrayApp.notificationsEnabled = checked
                    }

                    UiSwitch {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20
                        Layout.rightMargin: 20
                        visible: airPodsTrayApp.airpodsConnected
                        iconName: "headphone-off"
                        text: qsTr("One Bud ANC Mode")
                        description: qsTr("Enable ANC when using one AirPod\n(More noise reduction, but uses more battery)")
                        checked: airPodsTrayApp.deviceInfo.oneBudANCMode
                        onToggled: airPodsTrayApp.deviceInfo.oneBudANCMode = checked
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20
                        Layout.rightMargin: 20
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Bluetooth Retry Attempts:")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: Theme.foreground
                            wrapMode: Text.WordWrap
                        }

                        UiSpinBox {
                            from: 1
                            to: 10
                            value: airPodsTrayApp.retryAttempts
                            onValueModified: airPodsTrayApp.retryAttempts = value
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20
                        Layout.rightMargin: 20
                        spacing: 8
                        visible: airPodsTrayApp.airpodsConnected

                        Text {
                            text: qsTr("AirPods name")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: Theme.foreground
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            UiTextField {
                                id: newNameField
                                Layout.fillWidth: true
                                text: airPodsTrayApp.deviceInfo.deviceName
                                maximumLength: 32
                                invalid: renameError.text !== ""
                                onTextEdited: renameError.text = ""
                                onAccepted: if (renameButton.enabled) renameButton.clicked()
                            }

                            UiButton {
                                id: renameButton
                                variant: "outline"
                                iconName: "pencil"
                                text: qsTr("Rename")
                                enabled: newNameField.text.trim() !== "" && newNameField.text.trim() !== airPodsTrayApp.deviceInfo.deviceName
                                onClicked: {
                                    const name = newNameField.text.trim();
                                    const error = airPodsTrayApp.renameAirPods(name);
                                    if (error !== "")
                                        renameError.text = error;
                                    else
                                        toast.show(qsTr("Renamed to %1").arg(name));
                                }
                            }
                        }

                        Text {
                            id: renameError
                            Layout.fillWidth: true
                            visible: text !== ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: Theme.danger
                            wrapMode: Text.WordWrap
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 20
                        Layout.rightMargin: 20
                        spacing: 8

                        Text {
                            text: qsTr("Phone Bluetooth address")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: Theme.foreground
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Used by Cross-Device Connectivity. On Android, find it in Settings > About phone.")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: Theme.mutedForeground
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            UiTextField {
                                id: newPhoneMacField
                                readonly property bool complete: /^([0-9A-Fa-f]{2}([-:]?)){5}[0-9A-Fa-f]{2}$/.test(text)
                                Layout.fillWidth: true
                                text: PHONE_MAC_ADDRESS
                                placeholderText: "AA:BB:CC:DD:EE:FF"
                                maximumLength: 17
                                inputMethodHints: Qt.ImhPreferUppercase | Qt.ImhNoPredictiveText
                                validator: RegularExpressionValidator {
                                    regularExpression: /^([0-9A-Fa-f]{2}[-:]?){0,5}[0-9A-Fa-f]{0,2}$/
                                }
                                invalid: phoneMacError.text !== ""
                                onTextEdited: phoneMacError.text = ""
                                onAccepted: if (phoneMacButton.enabled) phoneMacButton.clicked()
                            }

                            UiButton {
                                id: phoneMacButton
                                variant: "outline"
                                iconName: "smartphone"
                                text: qsTr("Save")
                                enabled: newPhoneMacField.complete && newPhoneMacField.text.toUpperCase() !== PHONE_MAC_ADDRESS.toUpperCase()
                                onClicked: {
                                    const error = airPodsTrayApp.setPhoneMac(newPhoneMacField.text.toUpperCase());
                                    if (error !== "")
                                        phoneMacError.text = error;
                                    else
                                        toast.show(qsTr("Phone address saved"));
                                }
                            }
                        }

                        Text {
                            id: phoneMacError
                            Layout.fillWidth: true
                            visible: text !== ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: Theme.danger
                            wrapMode: Text.WordWrap
                        }
                    }

                    UiButton {
                        Layout.leftMargin: 20
                        variant: "outline"
                        iconName: "qr-code"
                        text: qsTr("Show Magic Cloud Keys QR")
                        onClicked: keysQrDialog.show()
                    }

                    KeysQRDialog {
                        id: keysQrDialog
                        encKey: airPodsTrayApp.deviceInfo.magicAccEncKey
                        irk: airPodsTrayApp.deviceInfo.magicAccIRK
                    }

                    Item { implicitHeight: 4 }
                }
            }
        }
    }
}
