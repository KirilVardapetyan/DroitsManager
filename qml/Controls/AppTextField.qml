import QtQuick
import QtQuick.Controls
import DroitsManager

Column {
    id: root

    property string label: ""
    property string placeholderText: ""
    property string hintText: ""
    property alias text: textField.text
    property alias readOnly: textField.readOnly

    signal accepted()

    function forceInputFocus() { textField.forceActiveFocus() }

    spacing: Theme.spacingSm
    width: parent ? parent.width : 200

    Text {
        visible: root.label !== ""
        text: root.label
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeNormal
    }

    Rectangle {
        width: parent.width
        height: Theme.inputHeight
        color: Theme.backgroundSecondary
        radius: Theme.radiusSm
        border.width: 1
        border.color: textField.activeFocus ? Theme.borderFocus : Theme.borderPrimary

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }

        TextField {
            id: textField
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingMd
            anchors.rightMargin: Theme.spacingMd
            verticalAlignment: TextInput.AlignVCenter
            placeholderText: root.placeholderText
            color: Theme.textPrimary
            placeholderTextColor: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            background: Item {}
            Keys.onReturnPressed: root.accepted()
        }
    }

    Text {
        visible: root.hintText !== ""
        text: root.hintText
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
    }
}
