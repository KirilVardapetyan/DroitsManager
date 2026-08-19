import QtQuick
import DroitsManager
import "../Components"

Rectangle {
    id: root

    color: Theme.backgroundPrimary

    Component.onCompleted: DroneStore.pollingActive = true
    Component.onDestruction: DroneStore.pollingActive = false

    PageHeader {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingXl
        title: qsTr("Drones")
        subtitle: qsTr("Flight drones and their connection state")
    }

    DroidsTable {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingXl
        title: qsTr("Drones")
        buttonText: qsTr("Connect Drone")
        nameColumnLabel: qsTr("Drone Name")
        emptyText: qsTr("No drones connected yet")
        rowIconSource: "qrc:/qt/qml/DroitsManager/assets/icons/nav_drone.svg"
        model: DroneStore
        showToggleButton: false
        showShellButton: true
        showVideoButton: true

        onConnectClicked: connectModal.open()
        onVideoClicked: function(index) {
            var drone = DroneStore.droneAt(index)
            videoModal.open(drone.name, drone.ipAddress)
        }
        onShellClicked: function(index) {
            var drone = DroneStore.droneAt(index)
            shellModal.open(drone.name, drone.ipAddress)
        }
        onRemoveClicked: function(index) {
            DroneStore.removeDrone(index)
        }
    }

    DroneShellModal {
        id: shellModal
    }

    DroneVideoModal {
        id: videoModal
    }

    ConnectDroidModal {
        id: connectModal
        title: qsTr("Connect Drone")
        nameLabel: qsTr("Drone Name")
        namePlaceholder: qsTr("e.g. Drone 1")
        onConnectRequested: function(name, ipAddress) {
            DroneStore.connectDrone(name, ipAddress)
        }
    }

    Connections {
        target: DroneStore

        function onConnectSucceeded() {
            connectModal.close()
        }

        function onConnectFailed(error) {
            connectModal.showError(error)
        }
    }
}
