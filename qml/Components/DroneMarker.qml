import QtQuick
import QtLocation
import DroitsManager

MapQuickItem {
    id: root

    property string droneName: ""
    property int satelliteCount: -1

    readonly property color satelliteColor: satelliteCount >= 6 ? Theme.success
                                          : satelliteCount >= 3 ? Theme.warning : Theme.error

    signal clicked()

    anchorPoint.x: pinContent.width / 2
    anchorPoint.y: 24
    z: 10

    sourceItem: Column {
        id: pinContent
        spacing: 2

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 48
            height: 48
            radius: 24
            color: Qt.rgba(24/255, 24/255, 27/255, 0.9)
            border.width: 1
            border.color: Theme.primary

            Image {
                anchors.centerIn: parent
                width: 26
                height: 26
                source: "qrc:/qt/qml/DroitsManager/assets/icons/nav_drone.svg"
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clicked()
            }

            Rectangle {
                visible: root.satelliteCount >= 0
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: -5
                anchors.rightMargin: -8
                width: satelliteRow.width + 10
                height: 16
                radius: 8
                color: Qt.rgba(24/255, 24/255, 27/255, 0.95)
                border.width: 1
                border.color: root.satelliteColor

                Row {
                    id: satelliteRow
                    anchors.centerIn: parent
                    spacing: 3

                    Rectangle {
                        width: 5
                        height: 5
                        radius: 2.5
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.satelliteColor

                        SequentialAnimation on opacity {
                            running: root.visible
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.35; duration: 900; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.35; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.satelliteCount
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        Rectangle {
            visible: root.droneName !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            width: pinLabel.width + 10
            height: 16
            radius: 8
            color: Qt.rgba(24/255, 24/255, 27/255, 0.85)
            border.width: 1
            border.color: Theme.borderSubtle

            Text {
                id: pinLabel
                anchors.centerIn: parent
                text: root.droneName
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }
    }
}
