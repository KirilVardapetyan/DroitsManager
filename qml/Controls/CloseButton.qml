import QtQuick
import DroitsManager

Rectangle {
    id: root

    signal clicked()

    width: 28
    height: 28
    radius: 14
    color: closeArea.containsMouse ? Theme.hoverLight : "transparent"

    Text {
        anchors.centerIn: parent
        text: "✕"
        color: Theme.textMuted
        font.pixelSize: Theme.fontSizeLarge
        font.family: Theme.fontFamily
    }

    MouseArea {
        id: closeArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
