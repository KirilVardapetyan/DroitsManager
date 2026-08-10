import QtQuick
import QtLocation
import DroidsManager

MapQuickItem {
    id: root

    property string boxName: ""

    signal clicked()

    anchorPoint.x: pinContent.width / 2
    anchorPoint.y: 24
    z: 9

    sourceItem: Column {
        id: pinContent
        spacing: 2

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 48
            height: 48
            radius: 24
            color: Qt.rgba(36/255, 20/255, 13/255, 0.9)
            border.width: 1
            border.color: Theme.borderSubtle

            Image {
                anchors.centerIn: parent
                width: 26
                height: 26
                source: "qrc:/qt/qml/DroidsManager/assets/icons/icon_box.svg"
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clicked()
            }
        }

        Rectangle {
            visible: root.boxName !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            width: pinLabel.width + 10
            height: 16
            radius: 8
            color: Qt.rgba(36/255, 20/255, 13/255, 0.85)
            border.width: 1
            border.color: Theme.borderSubtle

            Text {
                id: pinLabel
                anchors.centerIn: parent
                text: root.boxName
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }
}
