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
            rotationScale: 1/120
            property: "zoomLevel"
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
            onClicked: deliveryBoxModal.open()
        }
    }

    DeliveryBoxModal {
        id: deliveryBoxModal
        boxName: deliveryBoxMarker.boxName
        onOpenRequested: console.log("[LiveMap] Open requested for", boxName)
        onCloseRequested: console.log("[LiveMap] Close requested for", boxName)
    }
}
