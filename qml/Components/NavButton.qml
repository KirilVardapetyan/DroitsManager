import QtQuick
import QtQuick.Effects
import DroidsManager

Rectangle {
    id: root

    property string iconSource: ""
    property bool selected: false

    signal clicked()

    width: Theme.navIconSize
    height: Theme.navIconSize
    radius: Theme.radiusSm
    color: selected ? Theme.primary : Theme.backgroundSubtle

    Image {
        anchors.centerIn: parent
        width: 24
        height: 24
        source: root.iconSource
        fillMode: Image.PreserveAspectFit
        visible: root.selected
    }

    Image {
        anchors.centerIn: parent
        width: 24
        height: 24
        source: root.iconSource
        fillMode: Image.PreserveAspectFit
        visible: !root.selected
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: Theme.textTertiary
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
