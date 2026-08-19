import QtQuick
import DroitsManager

Rectangle {
    id: root

    enum Status {
        Pending,
        InProcess,
        Started,
        Delivered
    }

    property int status: OrderStatusBadge.Status.Pending

    readonly property var statusLabels: ({
        0: qsTr("Pending"),
        1: qsTr("In Process"),
        2: qsTr("Started"),
        3: qsTr("Delivered")
    })

    readonly property var statusColors: ({
        0: Theme.warning,
        1: Theme.info,
        2: Theme.accent,
        3: Theme.success
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
