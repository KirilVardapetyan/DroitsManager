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
            iconSource: "qrc:/qt/qml/DroidsManager/assets/icons/icon_box.svg"
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
        color: Theme.primary

        Image {
            anchors.centerIn: parent
            width: 24
            height: 24
            source: "qrc:/qt/qml/DroidsManager/assets/icons/icon_user.svg"
            fillMode: Image.PreserveAspectFit
        }
    }
}
