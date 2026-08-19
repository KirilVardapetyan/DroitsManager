import QtQuick
import DroitsManager

Rectangle {
    id: root

    property bool enabled: true
    property color backgroundColor: "transparent"
    property color hoverBackgroundColor: "transparent"
    property color pressedBackgroundColor: "transparent"
    property color borderColor: Theme.borderPrimary
    property color hoverBorderColor: Theme.borderFocus
    property color disabledBorderColor: Theme.borderSubtle
    property real horizontalPadding: Theme.spacingLg
    property real verticalPadding: Theme.spacingSm
    property real buttonHeight: 32
    readonly property bool containsMouse: buttonArea.containsMouse
    readonly property bool pressed: buttonArea.pressed
    default property alias contentData: contentRow.data

    signal clicked()

    implicitWidth: contentRow.width + (horizontalPadding * 2)
    implicitHeight: Math.max(buttonHeight, contentRow.height + (verticalPadding * 2))
    width: implicitWidth
    height: implicitHeight
    radius: Theme.radiusSm
    color: {
        if (!root.enabled)
            return root.backgroundColor
        if (buttonArea.pressed)
            return root.pressedBackgroundColor
        if (buttonArea.containsMouse)
            return root.hoverBackgroundColor
        return root.backgroundColor
    }
    opacity: root.enabled ? 1.0 : 0.6
    border.width: 1
    border.color: {
        if (!root.enabled)
            return root.disabledBorderColor
        if (buttonArea.containsMouse)
            return root.hoverBorderColor
        return root.borderColor
    }

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    Behavior on border.color {
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
