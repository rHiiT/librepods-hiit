// UiCard.qml
// LibrePods HiiT: bordered container with an optional title, in the shadcn/ui "Card" style.
// With `collapsible`, the title becomes a button that shows or hides the content.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: root

    property string title: ""
    property string description: ""
    property bool collapsible: false
    property bool expanded: true
    default property alias content: body.data

    implicitWidth: 360
    implicitHeight: column.implicitHeight + 2 * column.anchors.margins
    radius: Theme.radiusLarge
    color: Theme.card
    border.width: 1
    border.color: Theme.border

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        AbstractButton {
            id: header
            Layout.fillWidth: true
            visible: root.title !== ""
            enabled: root.collapsible
            focusPolicy: root.collapsible ? Qt.StrongFocus : Qt.NoFocus
            Accessible.role: root.collapsible ? Accessible.Button : Accessible.StaticText
            Accessible.name: root.title
            onClicked: root.expanded = !root.expanded

            contentItem: Item {
                implicitHeight: headerText.implicitHeight

                ColumnLayout {
                    id: headerText
                    anchors.left: parent.left
                    anchors.right: chevron.visible ? chevron.left : parent.right
                    anchors.rightMargin: chevron.visible ? 8 : 0
                    spacing: 4

                    Text {
                        text: root.title
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.capitalization: Font.AllUppercase
                        color: Theme.mutedForeground
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.description !== ""
                        text: root.description
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        color: Theme.mutedForeground
                        wrapMode: Text.WordWrap
                    }
                }

                Icon {
                    id: chevron
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.collapsible
                    name: "chevron-down"
                    color: Theme.mutedForeground
                    rotation: root.expanded ? 180 : 0

                    Behavior on rotation {
                        NumberAnimation { duration: Theme.animationDuration }
                    }
                }
            }

            background: Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: Theme.radius
                color: "transparent"
                border.width: header.visualFocus ? 2 : 0
                border.color: Theme.ring
            }
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            visible: root.expanded
            spacing: 16
        }
    }
}
