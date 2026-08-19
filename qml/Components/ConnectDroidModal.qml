import QtQuick
import DroitsManager
import "../Controls"

ModalShell {
    id: root

    property string nameLabel: qsTr("Box Name")
    property string namePlaceholder: qsTr("e.g. Box 2")
    property bool busy: false
    property string errorText: ""

    signal connectRequested(string name, string ipAddress)

    title: qsTr("Connect Box")
    modalWidth: 400

    function open() {
        nameField.text = ""
        ipField.text = ""
        root.busy = false
        root.errorText = ""
        root.visible = true
        nameField.forceInputFocus()
    }

    function showError(message) {
        root.busy = false
        root.errorText = message
    }

    AppTextField {
        id: nameField
        label: root.nameLabel
        placeholderText: root.namePlaceholder
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
        if (root.busy)
            return
        root.busy = true
        root.errorText = ""
        root.connectRequested(nameField.text, ipField.text)
    }

    Text {
        width: parent.width
        visible: root.errorText !== ""
        text: root.errorText
        color: Theme.error
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.WordWrap
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
                enabled: !root.busy && nameField.text.length > 0 && ipField.text.length > 0
                onClicked: root.submit()

                Text {
                    text: root.busy ? qsTr("Connecting…") : qsTr("Connect")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.Medium
                }
            }
        }
    }
}
