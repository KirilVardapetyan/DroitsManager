import QtQuick
import QtLocation
import QtPositioning
import DroitsManager
import "../Controls"

Item {
    id: root

    property string droneName: ""
    property string droneIp: ""
    property var mission: []
    property var order: null
    property bool followDrone: true
    property string shipError: ""

    // The flown-path breadcrumb keeps at most this many meters and is cut
    // from its oldest end once longer.
    property real maxTrailMeters: 5000

    property var trailSegmentLengths: []
    property real trailLength: 0

    signal exited()

    Component.onCompleted: rebuildMissionLayer()
    onMissionChanged: rebuildMissionLayer()

    function rebuildMissionLayer() {
        missionMarkersModel.clear()
        missionDashesModel.clear()
        var m = mission || []
        var coords = []
        for (var i = 0; i < m.length; ++i) {
            if (m[i].command === "rtl")
                continue
            coords.push(QtPositioning.coordinate(m[i].latitude, m[i].longitude))
            missionMarkersModel.append({ lat: m[i].latitude, lon: m[i].longitude,
                                         num: i + 1, cmd: m[i].command })
        }
        missionLine.path = coords

        var endsWithRtl = m.length > 0 && m[m.length - 1].command === "rtl"
        if (endsWithRtl && coords.length > 1)
            buildReturnDashes(coords[coords.length - 1], coords[0])
    }

    function buildReturnDashes(from, to) {
        var total = from.distanceTo(to)
        if (total <= 0)
            return
        var count = Math.max(3, Math.min(Math.ceil(total / 85), 150))
        var dashFraction = 0.6
        for (var i = 0; i < count; ++i) {
            var t1 = i / count
            var t2 = t1 + dashFraction / count
            missionDashesModel.append({
                lat1: from.latitude + (to.latitude - from.latitude) * t1,
                lon1: from.longitude + (to.longitude - from.longitude) * t1,
                lat2: from.latitude + (to.latitude - from.latitude) * t2,
                lon2: from.longitude + (to.longitude - from.longitude) * t2
            })
        }
    }

    function appendTrailPoint(latitude, longitude) {
        var c = QtPositioning.coordinate(latitude, longitude)
        var count = dronePath.pathLength()
        if (count > 0) {
            var last = dronePath.coordinateAt(count - 1)
            var d = last.distanceTo(c)
            if (d < 1)
                return
            trailSegmentLengths.push(d)
            trailLength += d
        }
        dronePath.addCoordinate(c)
        while (trailLength > maxTrailMeters && trailSegmentLengths.length > 0) {
            trailLength -= trailSegmentLengths.shift()
            dronePath.removeCoordinate(0)
        }
    }

    DroneTelemetry {
        id: telemetry
        host: root.droneIp
        active: root.visible
        updateHz: 5

        onPositionChanged: {
            if (!telemetry.hasPosition)
                return
            root.appendTrailPoint(telemetry.latitude, telemetry.longitude)
            if (root.followDrone)
                flightMap.center = QtPositioning.coordinate(telemetry.latitude, telemetry.longitude)
        }
    }

    ListModel { id: missionMarkersModel }
    ListModel { id: missionDashesModel }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        clip: true

        OsmMapPlugin { id: flightMapPlugin }

        Map {
            id: flightMap
            anchors.fill: parent
            plugin: flightMapPlugin
            center: root.mission && root.mission.length > 0
                    ? QtPositioning.coordinate(root.mission[0].latitude, root.mission[0].longitude)
                    : QtPositioning.coordinate(40.17038, 44.51981)
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

            MapPolyline {
                id: missionLine
                z: 1
                opacity: 0.85
                line.width: 3
                line.color: Theme.primary
            }

            Instantiator {
                model: missionDashesModel

                onObjectAdded: function(index, object) { flightMap.addMapItem(object) }
                onObjectRemoved: function(index, object) { flightMap.removeMapItem(object) }

                delegate: MapPolyline {
                    z: 1
                    line.width: 2.5
                    line.color: Theme.error
                    path: [QtPositioning.coordinate(model.lat1, model.lon1),
                           QtPositioning.coordinate(model.lat2, model.lon2)]
                }
            }

            Instantiator {
                model: missionMarkersModel

                onObjectAdded: function(index, object) { flightMap.addMapItem(object) }
                onObjectRemoved: function(index, object) { flightMap.removeMapItem(object) }

                delegate: MapQuickItem {
                    coordinate: QtPositioning.coordinate(model.lat, model.lon)
                    anchorPoint.x: 10
                    anchorPoint.y: 10
                    z: 3

                    sourceItem: Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        opacity: 0.9
                        color: model.cmd === "takeoff" ? Theme.success
                             : model.cmd === "land" ? Theme.warning : Theme.primary
                        border.width: 1.5
                        border.color: Theme.textPrimary

                        Text {
                            anchors.centerIn: parent
                            text: model.num
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }
                }
            }

            MapPolyline {
                id: dronePath
                z: 2
                line.width: 3
                line.color: Theme.info
            }

            DroneMarker {
                visible: telemetry.hasPosition
                coordinate: QtPositioning.coordinate(telemetry.latitude, telemetry.longitude)
                droneName: root.droneName
                satelliteCount: telemetry.satellites
            }
        }

        Rectangle {
            id: topBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 48
            color: Qt.rgba(28 / 255, 28 / 255, 32 / 255, 0.92)

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Theme.borderStrong
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingLg
                anchors.verticalCenter: parent.verticalCenter
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
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingLg
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingXl
                visible: root.order !== null

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        anchors.right: parent.right
                        text: root.order ? qsTr("Order · %1").arg(root.order.username) : ""
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }

                    Text {
                        anchors.right: parent.right
                        text: root.order ? root.order.orderedAt : ""
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.order
                          ? qsTr("%1, %2  →  %3, %4")
                                .arg(root.order.startLat.toFixed(5)).arg(root.order.startLon.toFixed(5))
                                .arg(root.order.endLat.toFixed(5)).arg(root.order.endLon.toFixed(5))
                          : ""
                    color: Theme.textTertiary
                    font.family: "monospace"
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }

        AhrsHud {
            id: hud
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: Theme.spacingLg
            roll: telemetry.roll
            pitch: telemetry.pitch
            yaw: telemetry.yaw
            live: telemetry.connected && telemetry.hasAttitude
        }

        VideoStreamView {
            id: videoPanel
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.spacingLg
            streamUri: DroneStore.videoUriFor(root.droneIp)
            active: root.visible
        }

        SlideToShip {
            id: shipSlider
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: hud.verticalCenter
            width: (videoPanel.x - (hud.x + hud.width)) / 2
            busy: DroneStore.startingMission

            onActivated: {
                root.shipError = ""
                DroneStore.startMission(root.droneIp)
            }
        }

        Text {
            anchors.left: shipSlider.left
            anchors.right: shipSlider.right
            anchors.bottom: shipSlider.top
            anchors.bottomMargin: Theme.spacingSm
            visible: root.shipError !== ""
            text: root.shipError
            color: Theme.error
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            style: Text.Outline
            styleColor: Theme.backgroundPrimary
        }

        Connections {
            target: DroneStore

            function onMissionStartSucceeded() {
                shipSlider.completed = true
            }

            function onMissionStartFailed(error) {
                root.shipError = error
                shipSlider.reset()
            }
        }
    }
}
