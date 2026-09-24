// WindowResizeHandles.qml
// LibrePods HiiT: invisible edges and corners that resize a frameless window
// through the window manager (startSystemResize).
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window

Item {
    id: root

    property int grip: 6

    anchors.fill: parent

    component Handle: Item {
        id: handle
        required property int edges
        required property int cursor

        HoverHandler {
            cursorShape: handle.cursor
        }

        DragHandler {
            target: null
            onActiveChanged: if (active) root.Window.window.startSystemResize(handle.edges)
        }
    }

    Handle { edges: Qt.LeftEdge; cursor: Qt.SizeHorCursor
        x: 0; y: root.grip; width: root.grip; height: parent.height - 2 * root.grip }
    Handle { edges: Qt.RightEdge; cursor: Qt.SizeHorCursor
        x: parent.width - root.grip; y: root.grip; width: root.grip; height: parent.height - 2 * root.grip }
    Handle { edges: Qt.TopEdge; cursor: Qt.SizeVerCursor
        x: root.grip; y: 0; width: parent.width - 2 * root.grip; height: root.grip }
    Handle { edges: Qt.BottomEdge; cursor: Qt.SizeVerCursor
        x: root.grip; y: parent.height - root.grip; width: parent.width - 2 * root.grip; height: root.grip }
    Handle { edges: Qt.TopEdge | Qt.LeftEdge; cursor: Qt.SizeFDiagCursor
        x: 0; y: 0; width: root.grip; height: root.grip }
    Handle { edges: Qt.TopEdge | Qt.RightEdge; cursor: Qt.SizeBDiagCursor
        x: parent.width - root.grip; y: 0; width: root.grip; height: root.grip }
    Handle { edges: Qt.BottomEdge | Qt.LeftEdge; cursor: Qt.SizeBDiagCursor
        x: 0; y: parent.height - root.grip; width: root.grip; height: root.grip }
    Handle { edges: Qt.BottomEdge | Qt.RightEdge; cursor: Qt.SizeFDiagCursor
        x: parent.width - root.grip; y: parent.height - root.grip; width: root.grip; height: root.grip }
}
