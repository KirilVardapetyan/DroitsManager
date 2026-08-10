import QtQuick
import DroidsManager
import "../Controls"

ModalShell {
    id: root

    signal connectRequested(string name, string ipAddress)

    title: qsTr("Connect Box")
    modalWidth: 400

    function open() {
        nameField.text = ""
        ipField.text = ""
        root.visible = true
        nameField.forceInputFocus()
    }

    AppTextField {
        id: nameField
        label: qsTr("Box Name")
        placeholderText: qsTr("e.g. Box 2")
    }

    AppTextField {
        id: ipField
        label: qsTr("IP Address")
        placeholderText: qsTr("e.g. 192.168.1.24")
        onAccepted: {
            if (nameField.text.length > 0 && ipField.text.length > 0)
                root.submit()
        }
    }

    function submit() {
        root.connectRequested(nameField.text, ipField.text)
        root.close()
    }

    Item {
        width: parent.width
        height: Theme.buttonHeight

        Row {
            anchors.right: parent.right
            spacing: Theme.spacingSm

            Rectangle {
                width: cancelBtnText.width + Theme.spacingXl * 2
                height: Theme.buttonHeight
                radius: Theme.radiusSm
                color: cancelBtnArea.containsMouse ? Theme.hoverSubtle : "transparent"

                Text {
                    id: cancelBtnText
                    anchors.centerIn: parent
                    text: qsTr("Cancel")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: cancelBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }

            PrimaryActionButton {
                enabled: nameField.text.length > 0 && ipField.text.length > 0
                onClicked: root.submit()

                Text {
                    text: qsTr("Connect")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.Medium
                }
            }
        }
    }
}
