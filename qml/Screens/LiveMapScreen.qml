import QtQuick
import QtLocation
import QtPositioning
import DroidsManager
import "../Components"

Rectangle {
    id: root

    readonly property var defaultCenter: QtPositioning.coordinate(40.17038, 44.51981)
    readonly property real defaultZoom: 15
    property real savedZoom: defaultZoom
    property var savedCenter: defaultCenter

    color: Theme.backgroundPrimary

    OsmMapPlugin { id: mapPlugin }

    Map {
        id: map
        anchors.fill: parent
        plugin: mapPlugin
        center: root.savedCenter
        zoomLevel: root.savedZoom
        copyrightsVisible: false

        property geoCoordinate startCentroid

        PinchHandler {
            id: pinch
            target: null
            onActiveChanged: if (active) {
                map.startCentroid = map.toCoordinate(pinch.centroid.position, false)
            }
            onScaleChanged: (delta) => {
                map.zoomLevel += Math.log2(delta)
                map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position)
            }
            onRotationChanged: (delta) => {
                map.bearing -= delta
                map.alignCoordinateToPoint(map.startCentroid, pinch.centroid.position)
            }
            grabPermissions: PointerHandler.TakeOverForbidden
        }

        WheelHandler {
            id: wheel
            acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                             ? PointerDevice.Mouse | PointerDevice.TouchPad
                             : PointerDevice.Mouse
            // Zoom anchored at the cursor: the coordinate under the pointer
            // stays fixed instead of drifting toward the map center.
            onWheel: function(event) {
                var coordinate = map.toCoordinate(wheel.point.position, false)
                map.zoomLevel += event.angleDelta.y / 120
                map.alignCoordinateToPoint(coordinate, wheel.point.position)
            }
        }

        DragHandler {
            id: drag
            target: null
            onTranslationChanged: (delta) => map.pan(-delta.x, -delta.y)
        }

        onZoomLevelChanged: root.savedZoom = map.zoomLevel
        onCenterChanged: root.savedCenter = map.center

        DeliveryBoxMarker {
            id: deliveryBoxMarker
            coordinate: root.defaultCenter
            boxName: qsTr("Box 1")
            onClicked: deliveryBoxDrawer.show()
        }
    }

    DeliveryBoxDrawer {
        id: deliveryBoxDrawer
        boxName: deliveryBoxMarker.boxName
        onOpenBoxRequested: console.log("[LiveMap] Open box requested for", boxName)
        onCloseBoxRequested: console.log("[LiveMap] Close box requested for", boxName)
    }
}
