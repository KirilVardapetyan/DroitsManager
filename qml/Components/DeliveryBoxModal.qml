import QtQuick
import DroidsManager
import "../Controls"

ModalShell {
    id: root

    property string boxName: ""

    signal openRequested()
    signal closeRequested()

    title: boxName !== "" ? boxName : qsTr("Delivery Box")
    modalWidth: 400

    Text {
        width: parent.width
        text: qsTr("Control the parcel hatch of this delivery box.")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeNormal
        wrapMode: Text.WordWrap
    }

    Row {
        anchors.right: parent.right
        spacing: Theme.spacingMd

        SecondaryActionButton {
            buttonHeight: Theme.buttonHeight
            onClicked: root.closeRequested()

            Text {
                text: qsTr("Close")
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
            }
        }

        PrimaryActionButton {
            onClicked: root.openRequested()

            Text {
                text: qsTr("Open")
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
            }
        }
    }
}
