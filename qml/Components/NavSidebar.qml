import QtQuick
import DroidsManager

Rectangle {
    id: root

    property int currentIndex: 0

    signal liveMapClicked()
    signal droidsClicked()

    width: Theme.navWidth
    color: Theme.backgroundOverlay
    border.width: 1
    border.color: Theme.borderSubtle

    Column {
        anchors.fill: parent

        Rectangle {
            width: parent.width
            height: 64
            color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Qt.rgba(233/255, 233/255, 233/255, 0.35)
            }

            Image {
                anchors.centerIn: parent
                width: 28
                height: 31
                source: "qrc:/qt/qml/DroidsManager/assets/images/logo_new.png"
                fillMode: Image.PreserveAspectFit
            }
        }

        Item {
            width: parent.width
            height: parent.height - 64

            Column {
                anchors.top: parent.top
                anchors.topMargin: Theme.spacingXxl
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.spacingLg

                NavButton {
                    iconSource: "qrc:/qt/qml/DroidsManager/assets/icons/nav_map.svg"
                    selected: root.currentIndex === 0
                    onClicked: root.liveMapClicked()
                }

                NavButton {
                    iconSource: "qrc:/qt/qml/DroidsManager/assets/icons/icon_drobot.svg"
                    selected: root.currentIndex === 1
                    onClicked: root.droidsClicked()
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.spacingLg
                anchors.horizontalCenter: parent.horizontalCenter
                width: 40
                height: 40
                radius: 20
                color: Theme.brandBlue

                Image {
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: "qrc:/qt/qml/DroidsManager/assets/icons/icon_user.svg"
                    fillMode: Image.PreserveAspectFit
                }
            }
        }
    }
}
