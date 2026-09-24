// PodColumn.qml
// Modified by LibrePods HiiT: original line-art illustrations instead of product photos,
// and a status line: "Charging", "Last reading" (stale level, explained on hover) or the ear state.
import QtQuick

Column {
    id: root
    property bool inEar: true
    property string illustration: "bud" // bud, case or headphones (assets/illustrations)
    property int batteryLevel: 0
    property bool isCharging: false
    property string indicator: ""
    property bool showsEarState: indicator !== ""
    property bool lastKnown: false // level is a last reading, not live
    property real targetOpacity: inEar && !lastKnown ? 1 : 0.5

    onLastKnownChanged: opacityTimer.restart()

    Timer {
        id: opacityTimer
        interval: 50
        onTriggered: illustrationIcon.opacity = root.targetOpacity
    }

    onInEarChanged: {
        opacityTimer.restart()
    }

    spacing: 10

    Icon {
        id: illustrationIcon
        name: root.illustration
        color: Theme.foreground
        size: 72
        mirror: root.indicator === "R"
        anchors.horizontalCenter: parent.horizontalCenter

        Behavior on opacity {
            NumberAnimation { duration: Theme.animationDuration }
        }
    }

    BatteryIndicator {
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: root.lastKnown ? 0.5 : 1
        batteryLevel: root.batteryLevel
        isCharging: root.isCharging
        indicator: root.indicator
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: text !== ""
            text: root.isCharging ? qsTr("Charging")
                : root.lastKnown ? qsTr("Last reading")
                : root.showsEarState ? (root.inEar ? qsTr("In ear") : qsTr("Out of ear"))
                : ""
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: root.isCharging ? Theme.success : Theme.mutedForeground
        }

        // Signals that hovering explains why the reading is not live
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.lastKnown && !root.isCharging
            name: "info"
            size: 12
            color: Theme.mutedForeground
        }
    }

    HoverHandler {
        id: hover
    }

    UiToolTip {
        visible: root.lastKnown && hover.hovered
        width: 220
        text: qsTr("The case only reports its battery while at least one bud is inside it. Put a bud back to update it.")
    }
}
