import QtQuick
import QtLocation
import QtPositioning
import DroitsManager
import "../Controls"

Item {
    id: root

    property string orderUsername: ""
    property double startLat: 0
    property double startLon: 0
    property double endLat: 0
    property double endLon: 0

    property int stepIndex: 0
    property int selectedDroneIndex: -1
    property var selectedDrone: ({})
    property bool missionValidated: false
    property string statusMessage: ""
    property bool statusIsError: false

    readonly property var commandCycle: ["takeoff", "waypoint", "land", "rtl"]

    signal cancelled()
    signal shippingStarted()

    Component.onCompleted: DroneStore.pollingActive = true
    Component.onDestruction: DroneStore.pollingActive = false

    ListModel { id: waypointsModel }

    function generateMission() {
        waypointsModel.clear()
        var homeLat = selectedDrone.hasPosition ? selectedDrone.latitude : root.startLat
        var homeLon = selectedDrone.hasPosition ? selectedDrone.longitude : root.startLon
        waypointsModel.append({ command: "takeoff",
                                latitude: homeLat.toFixed(6), longitude: homeLon.toFixed(6), altitude: "50" })
        waypointsModel.append({ command: "waypoint",
                                latitude: root.startLat.toFixed(6), longitude: root.startLon.toFixed(6), altitude: "50" })
        waypointsModel.append({ command: "waypoint",
                                latitude: root.endLat.toFixed(6), longitude: root.endLon.toFixed(6), altitude: "50" })
        waypointsModel.append({ command: "rtl", latitude: "", longitude: "", altitude: "" })
        rebuildPath()
    }

    function invalidateMission() {
        missionValidated = false
        statusMessage = ""
        statusIsError = false
        rebuildPath()
    }

    function waypointCoordinate(i) {
        var wp = waypointsModel.get(i)
        if (wp.command === "rtl")
            return null
        var lat = parseFloat(wp.latitude)
        var lon = parseFloat(wp.longitude)
        if (isNaN(lat) || isNaN(lon))
            return null
        return QtPositioning.coordinate(lat, lon)
    }

    function rebuildPath() {
        var coords = []
        for (var i = 0; i < waypointsModel.count; ++i) {
            var c = waypointCoordinate(i)
            if (c)
                coords.push(c)
        }
        missionPath.path = coords

        returnDashesModel.clear()
        var endsWithRtl = waypointsModel.count > 0
            && waypointsModel.get(waypointsModel.count - 1).command === "rtl"
        if (endsWithRtl && coords.length > 1)
            buildReturnDashes(coords[coords.length - 1], coords[0])
    }

    // MapPolyline has no dash style, so the rtl leg is drawn as short
    // segments: ~50 m dash / ~35 m gap, linearly interpolated (fine at
    // delivery distances), capped so a huge leg cannot flood the map.
    function buildReturnDashes(from, to) {
        var total = from.distanceTo(to)
        if (total <= 0)
            return
        var count = Math.max(3, Math.min(Math.ceil(total / 85), 150))
        var dashFraction = 0.6
        for (var i = 0; i < count; ++i) {
            var t1 = i / count
            var t2 = t1 + dashFraction / count
            returnDashesModel.append({
                lat1: from.latitude + (to.latitude - from.latitude) * t1,
                lon1: from.longitude + (to.longitude - from.longitude) * t1,
                lat2: from.latitude + (to.latitude - from.latitude) * t2,
                lon2: from.longitude + (to.longitude - from.longitude) * t2
            })
        }
    }

    function collectWaypoints() {
        var list = []
        for (var i = 0; i < waypointsModel.count; ++i) {
            var wp = waypointsModel.get(i)
            if (wp.command === "rtl") {
                list.push({ command: "rtl" })
                continue
            }
            var lat = parseFloat(wp.latitude)
            var lon = parseFloat(wp.longitude)
            var alt = parseFloat(wp.altitude)
            if (isNaN(lat) || isNaN(lon) || isNaN(alt)) {
                statusMessage = qsTr("Waypoint %1 has invalid coordinates").arg(i + 1)
                statusIsError = true
                return null
            }
            list.push({ command: wp.command, latitude: lat, longitude: lon, altitude: alt })
        }
        if (list.length === 0) {
            statusMessage = qsTr("The mission needs at least one waypoint")
            statusIsError = true
            return null
        }
        return list
    }

    function validateMission() {
        var waypoints = collectWaypoints()
        if (!waypoints)
            return
        statusMessage = ""
        statusIsError = false
        DroneStore.uploadMission(selectedDrone.ipAddress, waypoints)
    }

    Connections {
        target: DroneStore

        function onMissionUploadSucceeded(uploadedWaypoints) {
            root.missionValidated = true
            root.statusMessage = qsTr("Mission validated — %1 waypoints stored on the drone").arg(uploadedWaypoints)
            root.statusIsError = false
        }

        function onMissionUploadFailed(error) {
            root.missionValidated = false
            root.statusMessage = error
            root.statusIsError = true
        }
    }

    component StepChip: Row {
        id: chipRoot

        property int step: 0
        property string label: ""
        readonly property bool current: root.stepIndex === chipRoot.step

        spacing: Theme.spacingSm

        Rectangle {
            width: 22
            height: 22
            radius: 11
            anchors.verticalCenter: parent.verticalCenter
            color: chipRoot.current ? Theme.primary : "transparent"
            border.width: 1
            border.color: chipRoot.current ? Theme.primary : Theme.borderPrimary

            Text {
                anchors.centerIn: parent
                text: chipRoot.step + 1
                color: chipRoot.current ? Theme.textPrimary : Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: chipRoot.label
            color: chipRoot.current ? Theme.textPrimary : Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            font.weight: chipRoot.current ? Font.DemiBold : Font.Normal
        }
    }

    component WaypointField: Rectangle {
        id: fieldRoot

        // One-way model -> input sync that never fights the user's typing:
        // the text follows modelValue (e.g. after a marker drag) only while
        // the field is not focused.
        property string modelValue: ""
        property bool editable: true

        signal edited(string value)

        onModelValueChanged: {
            if (!fieldInput.activeFocus)
                fieldInput.text = modelValue
        }
        Component.onCompleted: fieldInput.text = modelValue

        width: 110
        height: 30
        radius: Theme.radiusXs
        color: Theme.backgroundSecondary
        border.width: 1
        border.color: fieldInput.activeFocus ? Theme.borderFocus : Theme.borderPrimary
        opacity: editable ? 1.0 : 0.35

        TextInput {
            id: fieldInput
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingSm
            anchors.rightMargin: Theme.spacingSm
            verticalAlignment: TextInput.AlignVCenter
            enabled: fieldRoot.editable
            color: Theme.textPrimary
            selectionColor: Theme.primary
            selectByMouse: true
            clip: true
            font.family: "monospace"
            font.pixelSize: Theme.fontSizeSmall
            onTextEdited: fieldRoot.edited(text)
        }
    }

    Item {
        id: stepsHeader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 48

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXl

            StepChip { step: 0; label: qsTr("Select Drone") }

            Rectangle {
                width: 32
                height: 1
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.borderPrimary
            }

            StepChip { step: 1; label: qsTr("Mission") }
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.stepIndex === 1 && root.selectedDrone.name !== undefined
                  ? qsTr("Drone: %1 (%2)").arg(root.selectedDrone.name).arg(root.selectedDrone.ipAddress)
                  : qsTr("Order: %1").arg(root.orderUsername)
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    Rectangle {
        id: contentContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: stepsHeader.bottom
        anchors.topMargin: Theme.spacingLg
        anchors.bottom: footer.top
        anchors.bottomMargin: Theme.spacingLg
        color: "transparent"
        radius: Theme.radiusSm
        border.width: 1
        border.color: Theme.borderStrong
        clip: true

        // Step 1 — pick an online drone.
        ListView {
            id: droneList
            anchors.fill: parent
            anchors.margins: Theme.spacingMd
            visible: root.stepIndex === 0
            model: DroneStore
            clip: true
            spacing: Theme.spacingSm
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                readonly property bool online: model.status === DroidStatusBadge.Status.Connected
                readonly property bool selected: root.selectedDroneIndex === model.index

                width: droneList.width
                height: 52
                radius: Theme.radiusSm
                color: selected ? Theme.backgroundRaised : "transparent"
                border.width: 1
                border.color: selected ? Theme.primary : Theme.borderRow
                opacity: online ? 1.0 : 0.45

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingLg
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingLg

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        source: "qrc:/qt/qml/DroitsManager/assets/icons/nav_drone.svg"
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.name
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeNormal
                        font.weight: Font.Medium
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.ipAddress
                        color: Theme.textSecondary
                        font.family: "monospace"
                        font.pixelSize: Theme.fontSizeSmall
                    }

                    DroidStatusBadge {
                        anchors.verticalCenter: parent.verticalCenter
                        status: model.status
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingLg
                    anchors.verticalCenter: parent.verticalCenter
                    visible: model.hasPosition
                    text: qsTr("GPS %1, %2 · %3 sats")
                          .arg(model.latitude.toFixed(5)).arg(model.longitude.toFixed(5))
                          .arg(model.satellites >= 0 ? model.satellites : "—")
                    color: Theme.textTertiary
                    font.family: "monospace"
                    font.pixelSize: Theme.fontSizeSmall
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: parent.online ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (parent.online)
                            root.selectedDroneIndex = model.index
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.stepIndex === 0 && droneList.count === 0
            text: qsTr("No drones added — connect one on the Drones screen first")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
        }

        // Step 2 — the mission on a fullscreen map, editable from the
        // floating panel below and by dragging markers directly.
        Item {
            anchors.fill: parent
            visible: root.stepIndex === 1

            OsmMapPlugin { id: missionMapPlugin }

            Map {
                id: missionMap
                anchors.fill: parent
                plugin: missionMapPlugin
                center: QtPositioning.coordinate((root.startLat + root.endLat) / 2,
                                                 (root.startLon + root.endLon) / 2)
                zoomLevel: 13
                copyrightsVisible: false

                property geoCoordinate startCentroid

                PinchHandler {
                    id: missionPinch
                    target: null
                    onActiveChanged: if (active) {
                        missionMap.startCentroid = missionMap.toCoordinate(missionPinch.centroid.position, false)
                    }
                    onScaleChanged: (delta) => {
                        missionMap.zoomLevel += Math.log2(delta)
                        missionMap.alignCoordinateToPoint(missionMap.startCentroid, missionPinch.centroid.position)
                    }
                    grabPermissions: PointerHandler.TakeOverForbidden
                }

                WheelHandler {
                    id: missionWheel
                    acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland"
                                     ? PointerDevice.Mouse | PointerDevice.TouchPad
                                     : PointerDevice.Mouse
                    onWheel: function(event) {
                        var coordinate = missionMap.toCoordinate(missionWheel.point.position, false)
                        missionMap.zoomLevel += event.angleDelta.y / 120
                        missionMap.alignCoordinateToPoint(coordinate, missionWheel.point.position)
                    }
                }

                DragHandler {
                    target: null
                    onTranslationChanged: (delta) => missionMap.pan(-delta.x, -delta.y)
                }

                MapPolyline {
                    id: missionPath
                    z: 1
                    line.width: 3
                    line.color: Theme.primary
                }

                Instantiator {
                    model: ListModel { id: returnDashesModel }

                    onObjectAdded: function(index, object) { missionMap.addMapItem(object) }
                    onObjectRemoved: function(index, object) { missionMap.removeMapItem(object) }

                    delegate: MapPolyline {
                        z: 1
                        line.width: 2.5
                        line.color: Theme.error
                        path: [QtPositioning.coordinate(model.lat1, model.lon1),
                               QtPositioning.coordinate(model.lat2, model.lon2)]
                    }
                }

                // Markers go through Instantiator + addMapItem instead of
                // MapItemView: delegate z is honored this way, keeping the
                // numbered points above the path lines.
                Instantiator {
                    model: waypointsModel

                    onObjectAdded: function(index, object) { missionMap.addMapItem(object) }
                    onObjectRemoved: function(index, object) { missionMap.removeMapItem(object) }

                    delegate: MapQuickItem {
                        readonly property real wpLat: parseFloat(model.latitude)
                        readonly property real wpLon: parseFloat(model.longitude)

                        visible: model.command !== "rtl" && !isNaN(wpLat) && !isNaN(wpLon)
                        coordinate: QtPositioning.coordinate(wpLat, wpLon)
                        anchorPoint.x: 14
                        anchorPoint.y: 14
                        z: 10

                        sourceItem: Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: model.command === "takeoff" ? Theme.success
                                 : model.command === "land" ? Theme.warning : Theme.primary
                            border.width: 2
                            border.color: Theme.textPrimary

                            Text {
                                anchors.centerIn: parent
                                text: model.index + 1
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                anchors.fill: parent
                                preventStealing: true
                                cursorShape: Qt.SizeAllCursor
                                onPositionChanged: function(mouse) {
                                    if (!pressed)
                                        return
                                    var mapPoint = mapToItem(missionMap, mouse.x, mouse.y)
                                    var c = missionMap.toCoordinate(Qt.point(mapPoint.x, mapPoint.y), false)
                                    waypointsModel.setProperty(model.index, "latitude", c.latitude.toFixed(6))
                                    waypointsModel.setProperty(model.index, "longitude", c.longitude.toFixed(6))
                                    root.invalidateMission()
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: waypointPanel
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.spacingLg
                width: Math.min(parent.width - Theme.spacingXl * 2, 680)
                height: panelColumn.implicitHeight + Theme.spacingLg * 2
                radius: Theme.radiusMd
                color: Qt.rgba(28 / 255, 28 / 255, 32 / 255, 0.94)
                border.width: 1
                border.color: Theme.borderStrong

                MouseArea {
                    anchors.fill: parent
                    onClicked: function(mouse) { mouse.accepted = true }
                }

                Column {
                    id: panelColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingLg
                    spacing: Theme.spacingMd

                    Row {
                        spacing: Theme.spacingXl

                        Text {
                            text: qsTr("#")
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            width: 20
                        }

                        Text { text: qsTr("Command"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; width: 96 }
                        Text { text: qsTr("Latitude"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; width: 110 }
                        Text { text: qsTr("Longitude"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; width: 110 }
                        Text { text: qsTr("Altitude (m)"); color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSmall; width: 80 }
                    }

                    ListView {
                        id: waypointList
                        width: parent.width
                        height: Math.min(contentHeight, 190)
                        model: waypointsModel
                        clip: true
                        spacing: Theme.spacingSm
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Row {
                            spacing: Theme.spacingXl

                            Text {
                                text: model.index + 1
                                color: Theme.textMuted
                                font.family: "monospace"
                                font.pixelSize: Theme.fontSizeSmall
                                width: 20
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            SecondaryActionButton {
                                buttonHeight: 30
                                horizontalPadding: 0
                                width: 96
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                    var next = root.commandCycle[
                                        (root.commandCycle.indexOf(model.command) + 1) % root.commandCycle.length]
                                    waypointsModel.setProperty(model.index, "command", next)
                                    root.invalidateMission()
                                }

                                Text {
                                    text: model.command
                                    color: Theme.textPrimary
                                    font.family: "monospace"
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                            }

                            WaypointField {
                                anchors.verticalCenter: parent.verticalCenter
                                editable: model.command !== "rtl"
                                modelValue: model.latitude
                                onEdited: function(value) {
                                    waypointsModel.setProperty(model.index, "latitude", value)
                                    root.invalidateMission()
                                }
                            }

                            WaypointField {
                                anchors.verticalCenter: parent.verticalCenter
                                editable: model.command !== "rtl"
                                modelValue: model.longitude
                                onEdited: function(value) {
                                    waypointsModel.setProperty(model.index, "longitude", value)
                                    root.invalidateMission()
                                }
                            }

                            WaypointField {
                                width: 80
                                anchors.verticalCenter: parent.verticalCenter
                                editable: model.command !== "rtl"
                                modelValue: model.altitude
                                onEdited: function(value) {
                                    waypointsModel.setProperty(model.index, "altitude", value)
                                    root.invalidateMission()
                                }
                            }

                            Rectangle {
                                width: 28
                                height: 28
                                radius: Theme.radiusXs
                                anchors.verticalCenter: parent.verticalCenter
                                color: removeArea.containsMouse ? Theme.errorTint : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: removeArea.containsMouse ? Theme.error : Theme.textMuted
                                    font.pixelSize: Theme.fontSizeNormal
                                    font.family: Theme.fontFamily
                                }

                                MouseArea {
                                    id: removeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        waypointsModel.remove(model.index)
                                        root.invalidateMission()
                                    }
                                }
                            }
                        }
                    }

                    SecondaryActionButton {
                        id: addWaypointButton
                        onClicked: {
                            // Keep a trailing rtl last: new waypoints go before it.
                            var insertAt = waypointsModel.count
                            if (insertAt > 0 && waypointsModel.get(insertAt - 1).command === "rtl")
                                insertAt -= 1
                            waypointsModel.insert(insertAt, { command: "waypoint",
                                                              latitude: root.endLat.toFixed(6),
                                                              longitude: root.endLon.toFixed(6),
                                                              altitude: "50" })
                            root.invalidateMission()
                        }

                        Text {
                            text: qsTr("+ Add Waypoint")
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }

    Item {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Theme.buttonHeight

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: footerButtons.left
            anchors.rightMargin: Theme.spacingLg
            visible: root.statusMessage !== ""
            text: root.statusMessage
            color: root.statusIsError ? Theme.error : Theme.success
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            elide: Text.ElideRight
        }

        Row {
            id: footerButtons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingSm

            SecondaryActionButton {
                buttonHeight: Theme.buttonHeight
                visible: root.stepIndex === 1
                enabled: !DroneStore.uploadingMission
                onClicked: {
                    root.invalidateMission()
                    root.stepIndex = 0
                }

                Text {
                    text: qsTr("Back")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.Medium
                }
            }

            SecondaryActionButton {
                buttonHeight: Theme.buttonHeight
                enabled: !DroneStore.uploadingMission
                onClicked: root.cancelled()

                Text {
                    text: qsTr("Cancel")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.Medium
                }
            }

            PrimaryActionButton {
                visible: root.stepIndex === 0
                enabled: root.selectedDroneIndex >= 0
                onClicked: {
                    root.selectedDrone = DroneStore.droneAt(root.selectedDroneIndex)
                    root.invalidateMission()
                    root.generateMission()
                    root.stepIndex = 1
                }

                Text {
                    text: qsTr("Next")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.Medium
                }
            }

            PrimaryActionButton {
                visible: root.stepIndex === 1 && !root.missionValidated
                enabled: !DroneStore.uploadingMission && waypointsModel.count > 0
                onClicked: root.validateMission()

                Text {
                    text: DroneStore.uploadingMission ? qsTr("Validating…") : qsTr("Validate Mission")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.Medium
                }
            }

            PrimaryActionButton {
                visible: root.stepIndex === 1 && root.missionValidated
                backgroundColor: Theme.success
                hoverBackgroundColor: Qt.darker(Theme.success, 1.15)
                pressedBackgroundColor: Qt.darker(Theme.success, 1.3)
                onClicked: root.shippingStarted()

                Text {
                    text: qsTr("Start Shipping")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.Medium
                }
            }
        }
    }
}
