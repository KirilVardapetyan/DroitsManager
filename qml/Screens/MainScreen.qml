import QtQuick
import DroidsManager
import "../Components"

Rectangle {
    id: root

    property string sectionName: qsTr("Dashboard")

    color: Theme.backgroundPrimary

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingXl
        spacing: Theme.spacingXl

        PageHeader {
            title: root.sectionName
            subtitle: qsTr("Droids Manager")
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
                text: qsTr("Nothing here yet")
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLarge
            }
        }
    }
}
