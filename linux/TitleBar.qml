// TitleBar.qml
// LibrePods HiiT: title bar for the frameless window: "LibrePods / HiiT Edition" logo,
// drag to move, and settings, minimize and close buttons.
import QtQuick
import QtQuick.Layouts
import QtQuick.Window

Rectangle {
    id: root

    property bool showSettings: true
    signal settingsRequested()

    implicitHeight: 64
    color: Theme.background

    // Drag anywhere on the bar (outside the buttons) to move the window
    DragHandler {
        target: null
        grabPermissions: PointerHandler.CanTakeOverFromAnything
        onActiveChanged: if (active) root.Window.window.startSystemMove()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 12
        spacing: 4

        // Logo
        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                text: "LibrePods"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.foreground
            }

            Text {
                text: "HiiT Edition"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: Theme.mutedForeground
            }
        }

        UiButton {
            visible: root.showSettings
            variant: "ghost"
            iconName: "settings"
            toolTipText: qsTr("Settings")
            onClicked: root.settingsRequested()
        }

        UiButton {
            variant: "ghost"
            iconName: "minus"
            // LibrePods HiiT: minimizing hides the window in the tray instead of leaving a
            // second entry in the taskbar
            toolTipText: qsTr("Minimize to tray")
            onClicked: root.Window.window.hide()
        }

        UiButton {
            variant: "ghost"
            iconName: "x"
            toolTipText: airPodsTrayApp.closeToTray ? qsTr("Close to tray") : qsTr("Quit")
            onClicked: root.Window.window.close()
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.border
    }
}
