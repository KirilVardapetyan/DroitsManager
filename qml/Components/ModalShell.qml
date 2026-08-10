import QtQuick
import DroidsManager
import "../Controls"

Item {
    id: root

    property string title: ""
    property int modalWidth: 480
    property bool showCloseButton: true
    property bool closeOnBackdropClick: true

    property color dimColor: Theme.overlay
    property color cardColor: Theme.backgroundModal
    property color cardBorderColor: Theme.borderSubtle
    property real modalRadius: Theme.radiusMd

    default property alias content: contentColumn.data

    signal closed()

    visible: false
    anchors.fill: parent
    z: Theme.zModal

    function open() {
        root.visible = true
    }

    function close() {
        root.visible = false
        root.closed()
    }

    Rectangle {
        anchors.fill: parent
        color: root.dimColor

        MouseArea {
            anchors.fill: parent
            onClicked: { if (root.closeOnBackdropClick) root.close() }
        }
    }

    Rectangle {
        id: card
        width: root.modalWidth
        anchors.centerIn: parent
        height: innerColumn.implicitHeight + Theme.spacingXxl * 2
        color: root.cardColor
        radius: root.modalRadius
        border.width: 1
        border.color: root.cardBorderColor

        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) { mouse.accepted = true }
        }

        Column {
            id: innerColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingXxl
            spacing: Theme.spacingXl

            Item {
                width: parent.width
                height: shellTitle.implicitHeight
                visible: root.title.length > 0 || root.showCloseButton

                Text {
                    id: shellTitle
                    width: parent.width - (root.showCloseButton ? 40 : 0)
                    text: root.title
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXLarge
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                CloseButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.showCloseButton
                    onClicked: root.close()
                }
            }

            Column {
                id: contentColumn
                width: parent.width
                spacing: Theme.spacingXl
            }
        }
    }
}
