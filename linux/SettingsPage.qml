// SettingsPage.qml
// LibrePods HiiT: settings grouped by what they affect (AirPods, controls, app, Android)
// with rarely used options collapsed under "Advanced". Moved out of Main.qml.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Page {
    id: root

    required property UiToast toast
    signal backRequested()

    title: qsTr("Settings")
    background: Rectangle { color: Theme.background }

    Shortcut {
        sequences: [StandardKey.Back, "Esc"]
        onActivated: root.backRequested()
    }

    header: Rectangle {
        implicitHeight: 48
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
                onClicked: root.backRequested()
            }

            Text {
                Layout.fillWidth: true
                text: root.title
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
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
            x: 20
            width: settingsScroll.availableWidth - 40
            spacing: 16

            Item { implicitHeight: 4 }

            // AirPods: settings stored on the device itself
            UiCard {
                Layout.fillWidth: true
                title: qsTr("AirPods")

                UiLabel {
                    Layout.fillWidth: true
                    visible: !airPodsTrayApp.airpodsConnected
                    tone: "muted"
                    text: qsTr("Connect your AirPods to change their name and noise control options.")
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: airPodsTrayApp.airpodsConnected
                    spacing: 8

                    UiLabel {
                        text: qsTr("AirPods name")
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
                                    root.toast.show(qsTr("Renamed to %1").arg(name));
                            }
                        }
                    }

                    UiLabel {
                        id: renameError
                        Layout.fillWidth: true
                        visible: text !== ""
                        tone: "danger"
                    }
                }

                // Hearing Aid is set up once, from an iPhone or iPad, after a hearing test; it is
                // shown as information only so an everyday toggle cannot switch it off by mistake
                RowLayout {
                    Layout.fillWidth: true
                    visible: airPodsTrayApp.airpodsConnected && airPodsTrayApp.deviceInfo.hearingAidEnabled
                    spacing: 10

                    Icon {
                        Layout.alignment: Qt.AlignTop
                        name: "ear"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        UiLabel {
                            Layout.fillWidth: true
                            text: qsTr("Hearing Aid")
                        }

                        UiLabel {
                            Layout.fillWidth: true
                            tone: "muted"
                            text: qsTr("On. Set up from an iPhone or iPad.")
                        }
                    }
                }

                UiSwitch {
                    Layout.fillWidth: true
                    visible: airPodsTrayApp.airpodsConnected
                    iconName: "headphone-off"
                    text: qsTr("One Bud ANC Mode")
                    description: qsTr("Enable ANC when using one AirPod\n(More noise reduction, but uses more battery)")
                    checked: airPodsTrayApp.deviceInfo.oneBudANCMode
                    onToggled: airPodsTrayApp.deviceInfo.oneBudANCMode = checked
                }
            }

            // Controls: how the computer reacts to the AirPods
            UiCard {
                Layout.fillWidth: true
                title: qsTr("Controls")

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    UiLabel {
                        Layout.fillWidth: true
                        text: qsTr("Pause Behavior When Removing AirPods:")
                    }

                    UiSelect {
                        Layout.fillWidth: true
                        model: [qsTr("One Removed"), qsTr("Both Removed"), qsTr("Never")]
                        currentIndex: airPodsTrayApp.earDetectionBehavior
                        onActivated: airPodsTrayApp.earDetectionBehavior = currentIndex
                    }
                }
            }

            // App: behavior of LibrePods on this computer
            UiCard {
                Layout.fillWidth: true
                title: qsTr("App")

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    UiLabel {
                        text: qsTr("Language")
                    }

                    UiSelect {
                        // Language names stay in their own language so anyone can find theirs.
                        // Only languages the Departure Mono font can draw are offered.
                        readonly property var codes: ["", "en", "pt_BR", "it_IT", "tr"]
                        Layout.fillWidth: true
                        model: [qsTr("System default"), "English", "Português (Brasil)", "Italiano", "Türkçe"]
                        currentIndex: Math.max(0, codes.indexOf(airPodsTrayApp.language))
                        onActivated: airPodsTrayApp.language = codes[currentIndex]
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    UiLabel {
                        text: qsTr("Theme")
                    }

                    UiSelect {
                        readonly property var modes: ["system", "light", "dark"]
                        Layout.fillWidth: true
                        model: [qsTr("System default"), qsTr("Light"), qsTr("Dark")]
                        currentIndex: Math.max(0, modes.indexOf(airPodsTrayApp.theme))
                        onActivated: airPodsTrayApp.theme = modes[currentIndex]
                    }
                }

                UiSwitch {
                    Layout.fillWidth: true
                    iconName: "power"
                    text: qsTr("Auto-Start on Login")
                    checked: airPodsTrayApp.autoStartManager.autoStartEnabled
                    onToggled: airPodsTrayApp.autoStartManager.autoStartEnabled = checked
                }

                UiSwitch {
                    Layout.fillWidth: true
                    visible: airPodsTrayApp.canHideFromTaskbar
                    iconName: "app-window"
                    text: qsTr("Show in taskbar")
                    checked: airPodsTrayApp.showInTaskbar
                    onToggled: airPodsTrayApp.showInTaskbar = checked
                }

                UiSwitch {
                    Layout.fillWidth: true
                    iconName: "panel-bottom-close"
                    text: qsTr("Close to tray")
                    checked: airPodsTrayApp.closeToTray
                    onToggled: airPodsTrayApp.closeToTray = checked
                }

                UiSwitch {
                    Layout.fillWidth: true
                    iconName: "bell"
                    text: qsTr("Enable System Notifications")
                    checked: airPodsTrayApp.notificationsEnabled
                    onToggled: airPodsTrayApp.notificationsEnabled = checked
                }
            }

            // Android: link with the LibrePods Android app
            UiCard {
                Layout.fillWidth: true
                title: qsTr("Android")

                UiSwitch {
                    Layout.fillWidth: true
                    iconName: "smartphone"
                    text: qsTr("Cross-Device Connectivity with Android")
                    description: qsTr("Hand the AirPods over between this computer and your phone.")
                    checked: airPodsTrayApp.crossDeviceEnabled
                    onToggled: airPodsTrayApp.setCrossDeviceEnabled(checked)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: airPodsTrayApp.crossDeviceEnabled
                    spacing: 8

                    UiLabel {
                        text: qsTr("Phone Bluetooth address")
                    }

                    UiLabel {
                        Layout.fillWidth: true
                        tone: "muted"
                        text: qsTr("On Android, find it in Settings > About phone.")
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
                                    root.toast.show(qsTr("Phone address saved"));
                            }
                        }
                    }

                    UiLabel {
                        id: phoneMacError
                        Layout.fillWidth: true
                        visible: text !== ""
                        tone: "danger"
                    }
                }
            }

            // Advanced: troubleshooting and pairing data, collapsed by default
            UiCard {
                Layout.fillWidth: true
                title: qsTr("Advanced")
                collapsible: true
                expanded: false

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        UiLabel {
                            Layout.fillWidth: true
                            text: qsTr("Bluetooth Retry Attempts:")
                        }

                        UiLabel {
                            Layout.fillWidth: true
                            tone: "muted"
                            text: qsTr("How many times to retry before giving up on a connection.")
                        }
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
                    spacing: 8

                    UiLabel {
                        Layout.fillWidth: true
                        tone: "muted"
                        text: qsTr("Scan with the LibrePods Android app so it can identify these AirPods and read their battery over Bluetooth.")
                    }

                    UiButton {
                        variant: "outline"
                        iconName: "qr-code"
                        text: qsTr("Show Magic Cloud Keys QR")
                        onClicked: keysQrDialog.show()
                    }
                }
            }

            // Experimental: features still being tested, collapsed and off by default
            UiCard {
                Layout.fillWidth: true
                title: qsTr("Experimental")
                description: qsTr("Features still being tested. They may not work correctly.")
                collapsible: true
                expanded: false

                UiSwitch {
                    Layout.fillWidth: true
                    iconName: "bluetooth-searching"
                    text: qsTr("Connect AirPods detected nearby")
                    description: qsTr("When the AirPods case is opened near this computer, show a Connect button. The AirPods may not always switch from another device.")
                    checked: airPodsTrayApp.nearbyConnectEnabled
                    onToggled: airPodsTrayApp.nearbyConnectEnabled = checked
                }
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
