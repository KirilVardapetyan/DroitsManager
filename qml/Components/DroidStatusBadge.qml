import QtQuick
import DroidsManager

Rectangle {
    id: root

    enum Status {
        Offline,
        Connected
    }

    property int status: DroidStatusBadge.Status.Offline

    readonly property var statusLabels: ({
        0: qsTr("Offline"),
        1: qsTr("Connected")
    })

    readonly property var statusColors: ({
        0: Theme.error,
        1: Theme.success
    })

    width: badgeLabel.width + Theme.spacingLg
    height: 24
    radius: Theme.radiusXs
    color: Qt.rgba(statusColors[root.status].r, statusColors[root.status].g, statusColors[root.status].b, 0.15)
    border.width: 1
    border.color: Qt.rgba(statusColors[root.status].r, statusColors[root.status].g, statusColors[root.status].b, 0.4)

    Text {
        id: badgeLabel
        anchors.centerIn: parent
        text: root.statusLabels[root.status] || ""
        color: root.statusColors[root.status] || Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
    }
}
