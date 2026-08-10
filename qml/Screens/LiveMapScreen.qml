import QtQuick
import DroidsManager
import "../Components"

Rectangle {
    color: Theme.backgroundPrimary

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingXl
        spacing: Theme.spacingXl

        PageHeader {
            title: qsTr("Live Map")
            subtitle: qsTr("Real-time droid positions")
        }

        Rectangle {
            width: parent.width
            height: 400
            radius: Theme.radiusMd
            color: Theme.backgroundCard
            border.width: 1
            border.color: Theme.borderSubtle

            Text {
                anchors.centerIn: parent
                text: qsTr("Map coming soon")
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
            }
        }
    }
}
