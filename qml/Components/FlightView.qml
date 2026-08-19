import QtQuick
import QtLocation
import QtPositioning
import DroitsManager
import "../Controls"

Item {
    id: root

    property string droneName: ""
    property string droneIp: ""
    property bool followDrone: true

    signal exited()

    DroneTelemetry {
        id: telemetry
        host: root.droneIp
        active: root.visible
        updateHz: 5

        onPositionChanged: {
            if (root.followDrone && telemetry.hasPosition)
                flightMap.center = QtPositioning.coordinate(telemetry.latitude, telemetry.longitude)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: Theme.radiusSm
        border.width: 1
        border.color: Theme.borderStrong
        clip: true

        OsmMapPlugin { id: flightMapPlugin }

        Map {
            id: flightMap
            anchors.fill: parent
            plugin: flightMapPlugin
            center: QtPositioning.coordinate(40.17038, 44.51981)
            zoomLevel: 15
            copyrightsVisible: false

            property geoCoordinate startCentroid

            PinchHandler {
                id: flightPinch
                target: null
                onActiveChanged: if (active) {
                    flightMap.startCentroid = flightMap.toCoordinate(flightPinch.centroid.position, false)
                }
                onScaleChanged: (delta) => {
                    flightMap.zoomLevel += Math.log2(delta)
                    flightMap.alignCoordinateToPoint(flightMap.startCentroid, flightPinch.centroid.position)
                }
                grabPermissions: PointerHandler.TakeOverForbidden
            }

            WheelHandler {
                id: flightWheel
                acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                                 ? PointerDevice.Mouse | PointerDevice.TouchPad
                                 : PointerDevice.Mouse
                onWheel: function(event) {
                    var coordinate = flightMap.toCoordinate(flightWheel.point.position, false)
                    flightMap.zoomLevel += event.angleDelta.y / 120
                    flightMap.alignCoordinateToPoint(coordinate, flightWheel.point.position)
                }
            }

            DragHandler {
                target: null
                onTranslationChanged: (delta) => {
                    root.followDrone = false
                    flightMap.pan(-delta.x, -delta.y)
                }
            }

            DroneMarker {
                visible: telemetry.hasPosition
                coordinate: QtPositioning.coordinate(telemetry.latitude, telemetry.longitude)
                droneName: root.droneName
                satelliteCount: telemetry.satellites
            }
        }

        Row {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Theme.spacingLg
            spacing: Theme.spacingSm

            Rectangle {
                width: 8
                height: 8
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: telemetry.connected ? Theme.success : Theme.error
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("%1 · %2").arg(root.droneName)
                      .arg(telemetry.connected ? qsTr("telemetry live") : qsTr("connecting…"))
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                style: Text.Outline
                styleColor: Theme.backgroundPrimary
            }
        }

        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingLg
            spacing: Theme.spacingSm

            SecondaryActionButton {
                visible: !root.followDrone
                onClicked: {
                    root.followDrone = true
                    if (telemetry.hasPosition)
                        flightMap.center = QtPositioning.coordinate(telemetry.latitude, telemetry.longitude)
                }

                Text {
                    text: qsTr("Follow Drone")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }
            }

            SecondaryActionButton {
                onClicked: root.exited()

                Text {
                    text: qsTr("End Flight")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }
            }
        }

        AhrsHud {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: Theme.spacingLg
            roll: telemetry.roll
            pitch: telemetry.pitch
            yaw: telemetry.yaw
            live: telemetry.connected && telemetry.hasAttitude
        }

        VideoStreamView {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.spacingLg
        }
    }
}
