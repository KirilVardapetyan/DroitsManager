import QtQuick
import QtMultimedia
import DroitsManager
import "../Controls"

Rectangle {
    id: root

    property string boxName: ""
    property string boxIp: ""
    property bool boxOpen: false
    property bool opened: false

    readonly property bool hasBox: boxIp !== ""

    signal openBoxRequested()
    signal closeBoxRequested()

    function show() {
        root.opened = true
    }

    function hide() {
        root.opened = false
    }

    width: 320
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.rightMargin: opened ? 0 : -width
    z: Theme.zOverlay
    color: Theme.backgroundOverlay
    border.width: 1
    border.color: Theme.borderSubtle

    Behavior on anchors.rightMargin {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: function(mouse) { mouse.accepted = true }
    }

    Connections {
        target: BoxClient

        function onCommandSucceeded(command) {
            root.boxOpen = command === "open"
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingXl
        spacing: Theme.spacingXl

        Item {
            width: parent.width
            height: 30

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.boxName !== "" ? root.boxName : qsTr("Delivery Box")
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXLarge
                font.weight: Font.DemiBold
            }

            CloseButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.hide()
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.hoverLight
        }

        Text {
            width: parent.width
            visible: !root.hasBox
            text: qsTr("No box connected yet. Add one from the Droids screen.")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeNormal
            wrapMode: Text.WordWrap
        }

        Column {
            width: parent.width
            visible: root.hasBox
            spacing: Theme.spacingMd

            Text {
                text: qsTr("Connection")
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Font.DemiBold
            }

            Text {
                text: root.boxIp
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
            }
        }

        Column {
            width: parent.width
            visible: root.hasBox
            spacing: Theme.spacingMd

            Text {
                text: qsTr("Live Video")
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Font.DemiBold
            }

            Rectangle {
                width: parent.width
                height: Math.round(width * 9 / 16)
                radius: Theme.radiusSm
                color: "#000000"
                border.width: 1
                border.color: Theme.borderStrong
                clip: true

                BoxVideoReceiver {
                    id: previewReceiver
                    uri: root.hasBox ? BoxStore.videoUriFor(root.boxIp) : ""
                    active: root.opened && root.hasBox
                    videoSink: previewOutput.videoSink
                }

                VideoOutput {
                    id: previewOutput
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectFit
                }

                Text {
                    anchors.centerIn: parent
                    visible: !previewReceiver.receiving
                    text: qsTr("Waiting for video…")
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }

        Column {
            width: parent.width
            visible: root.hasBox
            spacing: Theme.spacingMd

            Text {
                text: qsTr("Box Control")
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Font.DemiBold
            }

            PrimaryActionButton {
                width: parent.width
                enabled: !BoxClient.busy
                onClicked: {
                    BoxClient.host = root.boxIp
                    if (root.boxOpen) {
                        root.closeBoxRequested()
                        BoxClient.closeBox()
                    } else {
                        root.openBoxRequested()
                        BoxClient.openBox()
                    }
                }

                Text {
                    text: {
                        if (BoxClient.busy)
                            return qsTr("Sending…")
                        return root.boxOpen ? qsTr("Close Box") : qsTr("Open Box")
                    }
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.Medium
                }
            }

            Text {
                width: parent.width
                visible: BoxClient.statusMessage !== ""
                text: BoxClient.statusMessage
                color: BoxClient.hasError ? Theme.error : Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }
        }
    }
}
