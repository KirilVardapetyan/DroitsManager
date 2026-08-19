import QtQuick
import DroitsManager

// Placeholder for the drone video feed — receiving is not implemented yet,
// only the panel the stream will render into.
Rectangle {
    id: root

    property string streamUri: ""

    width: 300
    height: 200
    radius: Theme.radiusMd
    color: "#0b0b0e"
    border.width: 1
    border.color: Theme.borderStrong

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacingSm

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 34
            height: 24
            radius: Theme.radiusXs
            color: "transparent"
            border.width: 2
            border.color: Theme.textSecondary

            Rectangle {
                anchors.left: parent.right
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 12
                radius: 2
                color: Theme.textSecondary
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("VIDEO")
            color: Theme.textSecondary
            font.family: "monospace"
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.DemiBold
        }
    }
}
