import QtQuick
import DroitsManager
import "../Components"

Rectangle {
    id: root

    property int shippingOrderIndex: -1
    property var shippingOrder: null
    property var flightDrone: null
    property var flightMission: []
    readonly property bool preparingFlight: shippingOrderIndex >= 0
    readonly property bool inFlight: flightDrone !== null

    color: Theme.backgroundPrimary

    ListModel {
        id: ordersModel

        Component.onCompleted: {
            append({
                username: "aram.h",
                startLat: 40.17612, startLon: 44.50134,
                endLat: 40.19284, endLon: 44.54871,
                orderedAt: "Aug 11, 09:14",
                status: OrderStatusBadge.Status.Pending
            })
            append({
                username: "narine92",
                startLat: 40.16204, startLon: 44.47893,
                endLat: 40.18437, endLon: 44.52016,
                orderedAt: "Aug 11, 09:38",
                status: OrderStatusBadge.Status.InProcess
            })
            append({
                username: "tigran.dev",
                startLat: 40.20115, startLon: 44.56342,
                endLat: 40.17038, endLon: 44.51981,
                orderedAt: "Aug 11, 10:02",
                status: OrderStatusBadge.Status.Pending
            })
            append({
                username: "lusine_k",
                startLat: 40.15873, startLon: 44.46512,
                endLat: 40.20642, endLon: 44.55307,
                orderedAt: "Aug 11, 10:27",
                status: OrderStatusBadge.Status.Started
            })
            append({
                username: "davit77",
                startLat: 40.18926, startLon: 44.53468,
                endLat: 40.16351, endLon: 44.49025,
                orderedAt: "Aug 11, 11:05",
                status: OrderStatusBadge.Status.Delivered
            })
            append({
                username: "mher.a",
                startLat: 40.19457, startLon: 44.48761,
                endLat: 40.20873, endLon: 44.56694,
                orderedAt: "Aug 11, 11:41",
                status: OrderStatusBadge.Status.Pending
            })
        }
    }

    PageHeader {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingXl
        title: root.inFlight ? qsTr("Flight")
             : root.preparingFlight ? qsTr("Prepare Flight") : qsTr("Orders")
        subtitle: root.inFlight ? qsTr("Live shipping flight telemetry")
                : root.preparingFlight
                  ? qsTr("Pick a drone and validate the delivery mission")
                  : qsTr("Deliveries scheduled for your droids")
    }

    OrdersTable {
        visible: !root.preparingFlight && !root.inFlight
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingXl
        title: qsTr("Delivery Orders")
        model: ordersModel

        onStartShippingClicked: function(index) {
            root.shippingOrder = ordersModel.get(index)
            root.shippingOrderIndex = index
        }
        onAbortClicked: function(index) {
            ordersModel.setProperty(index, "status", OrderStatusBadge.Status.Pending)
        }
    }

    Loader {
        active: root.preparingFlight
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingXl

        sourceComponent: FlightPrepFlow {
            orderUsername: root.shippingOrder ? root.shippingOrder.username : ""
            startLat: root.shippingOrder ? root.shippingOrder.startLat : 0
            startLon: root.shippingOrder ? root.shippingOrder.startLon : 0
            endLat: root.shippingOrder ? root.shippingOrder.endLat : 0
            endLon: root.shippingOrder ? root.shippingOrder.endLon : 0

            onCancelled: root.shippingOrderIndex = -1
            onShippingStarted: function(drone, mission) {
                ordersModel.setProperty(root.shippingOrderIndex, "status",
                                        OrderStatusBadge.Status.Started)
                root.shippingOrderIndex = -1
                root.flightMission = mission
                root.flightDrone = drone
            }
        }
    }

    Loader {
        active: root.inFlight
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingXl

        sourceComponent: FlightView {
            droneName: root.flightDrone ? root.flightDrone.name : ""
            droneIp: root.flightDrone ? root.flightDrone.ipAddress : ""
            mission: root.flightMission

            onExited: root.flightDrone = null
        }
    }
}
