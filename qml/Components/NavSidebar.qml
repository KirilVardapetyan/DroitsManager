import QtQuick
import DroitsManager

Rectangle {
    id: root

    property int currentIndex: 0

    signal liveMapClicked()
    signal droidsClicked()
    signal ordersClicked()
    signal dronesClicked()

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
            iconSource: "qrc:/qt/qml/DroitsManager/assets/icons/nav_map.svg"
            selected: root.currentIndex === 0
            onClicked: root.liveMapClicked()
        }

        NavButton {
            iconSource: "qrc:/qt/qml/DroitsManager/assets/icons/icon_box.svg"
            selected: root.currentIndex === 1
            onClicked: root.droidsClicked()
        }

        NavButton {
            iconSource: "qrc:/qt/qml/DroitsManager/assets/icons/nav_orders.svg"
            selected: root.currentIndex === 2
            onClicked: root.ordersClicked()
        }

        NavButton {
            iconSource: "qrc:/qt/qml/DroitsManager/assets/icons/nav_drone.svg"
            selected: root.currentIndex === 3
            onClicked: root.dronesClicked()
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
            source: "qrc:/qt/qml/DroitsManager/assets/icons/icon_user.svg"
            fillMode: Image.PreserveAspectFit
        }
    }
}
