import QtQuick
import DroidsManager

Item {
    id: root

    property string title: ""
    property string subtitle: ""

    width: parent ? parent.width : 0
    height: column.height

    Column {
        id: column
        width: parent.width
        spacing: Theme.spacingXs

        Text {
            text: root.title
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeTitle
            font.weight: Font.Bold
        }

        Text {
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
        }
    }
}
