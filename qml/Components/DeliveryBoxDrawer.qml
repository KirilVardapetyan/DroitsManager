import QtQuick
import DroidsManager
import "../Controls"

Rectangle {
    id: root

    property string boxName: ""
    property bool boxOpen: false
    property bool opened: false

    signal openBoxRequested()
    signal closeBoxRequested()

    function show() {
        root.opened = true
    }

    function hide() {
        root.opened = false
    }

    width: 320
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.rightMargin: opened ? 0 : -width
    z: Theme.zOverlay
    color: Theme.backgroundOverlay
    border.width: 1
    border.color: Theme.borderSubtle

    Behavior on anchors.rightMargin {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: function(mouse) { mouse.accepted = true }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingXl
        spacing: Theme.spacingXl

        Item {
            width: parent.width
            height: 30

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.boxName !== "" ? root.boxName : qsTr("Delivery Box")
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXLarge
                font.weight: Font.DemiBold
            }

            CloseButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.hide()
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.hoverLight
        }

        Column {
            width: parent.width
            spacing: Theme.spacingMd

            Text {
                text: qsTr("Box Control")
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Font.DemiBold
            }

            PrimaryActionButton {
                width: parent.width
                onClicked: {
                    root.boxOpen = !root.boxOpen
                    if (root.boxOpen)
                        root.openBoxRequested()
                    else
                        root.closeBoxRequested()
                }

                Text {
                    text: root.boxOpen ? qsTr("Close Box") : qsTr("Open Box")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.Medium
                }
            }
        }
    }
}
