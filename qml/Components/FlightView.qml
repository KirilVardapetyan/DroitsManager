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
    property bool followDrone: true

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
        radius: Theme.radiusSm
        border.width: 1
        border.color: Theme.borderStrong
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
