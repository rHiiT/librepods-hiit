// PodColumn.qml
// Modified by LibrePods HiiT: original line-art illustrations instead of product photos,
// and a status line: "Charging", "Last reading" (stale level) or the ear state.
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

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: text !== ""
        text: root.isCharging ? qsTr("Charging")
            : root.lastKnown ? qsTr("Last reading")
            : root.showsEarState ? (root.inEar ? qsTr("In ear") : qsTr("Out of ear"))
            : ""
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: root.isCharging ? Theme.success : Theme.mutedForeground
    }
}
