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
            title: qsTr("Droids")
            subtitle: qsTr("Connected droids and their state")
        }

        Rectangle {
            width: parent.width
            height: 200
            radius: Theme.radiusMd
            color: Theme.backgroundCard
            border.width: 1
            border.color: Theme.borderSubtle

            Text {
                anchors.centerIn: parent
                text: qsTr("No droids connected yet")
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
            }
        }
    }
}
