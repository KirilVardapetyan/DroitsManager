import QtQuick
import DroidsManager

Rectangle {
    id: root

    property bool enabled: true
    property color backgroundColor: Theme.primary
    property color hoverBackgroundColor: Theme.primaryHover
    property color pressedBackgroundColor: Theme.primaryPressed
    property color disabledBackgroundColor: Qt.darker(backgroundColor, 1.5)
    property real horizontalPadding: Theme.spacingLg + (Theme.spacingSm / 2)
    property real verticalPadding: Theme.spacingSm
    property real buttonHeight: Theme.buttonHeight
    property real cornerRadius: Theme.radiusSm
    default property alias contentData: contentRow.data

    signal clicked()

    implicitWidth: contentRow.width + (horizontalPadding * 2)
    implicitHeight: Math.max(buttonHeight, contentRow.height + (verticalPadding * 2))
    width: implicitWidth
    height: implicitHeight
    radius: cornerRadius
    color: {
        if (!root.enabled)
            return root.disabledBackgroundColor
        if (buttonArea.pressed)
            return root.pressedBackgroundColor
        if (buttonArea.containsMouse)
            return root.hoverBackgroundColor
        return root.backgroundColor
    }

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: Theme.spacingSm
    }

    MouseArea {
        id: buttonArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
