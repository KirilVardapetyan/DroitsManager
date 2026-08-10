import QtQuick
import DroidsManager
import "../Components"

Rectangle {
    id: root

    color: Theme.backgroundPrimary

    ListModel { id: boxesModel }

    PageHeader {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingXl
        title: qsTr("Droids")
        subtitle: qsTr("Delivery boxes and their connection state")
    }

    DroidsTable {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingXl
        title: qsTr("Delivery Boxes")
        buttonText: qsTr("Connect Box")
        model: boxesModel

        onConnectClicked: connectModal.open()
        onToggleClicked: function(index) {
            var current = boxesModel.get(index).status
            boxesModel.setProperty(index, "status",
                current === DroidStatusBadge.Status.Connected
                ? DroidStatusBadge.Status.Offline
                : DroidStatusBadge.Status.Connected)
        }
        onRemoveClicked: function(index) {
            boxesModel.remove(index)
        }
    }

    ConnectDroidModal {
        id: connectModal
        onConnectRequested: function(name, ipAddress) {
            boxesModel.append({
                name: name,
                ipAddress: ipAddress,
                status: DroidStatusBadge.Status.Connected
            })
        }
    }
}
