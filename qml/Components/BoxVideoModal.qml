import QtQuick
import QtMultimedia
import DroitsManager
import "../Controls"

ModalShell {
    id: root

    property string boxName: ""
    property string ipAddress: ""

    title: root.boxName !== "" ? qsTr("%1 — Live Video").arg(root.boxName) : qsTr("Live Video")
    modalWidth: 720

    function open(name, ipAddress) {
        root.boxName = name
        root.ipAddress = ipAddress
        root.visible = true
    }

    onClosed: {
        root.boxName = ""
        root.ipAddress = ""
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
            id: videoReceiver
            uri: root.ipAddress !== "" ? BoxStore.videoUriFor(root.ipAddress) : ""
            active: root.visible && root.ipAddress !== ""
            videoSink: videoOutput.videoSink
        }

        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectFit
        }

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingMd
            visible: !videoReceiver.receiving

            Rectangle {
                width: 48
                height: 48
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 24
                color: "transparent"
                border.width: 3
                border.color: Theme.primary

                Rectangle {
                    width: 12
                    height: 3
                    radius: 1.5
                    color: Theme.primary
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: -1
                }

                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: root.visible && !videoReceiver.receiving
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Waiting for video stream…")
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
            }
        }
    }

    Text {
        width: parent.width
        visible: root.ipAddress !== ""
        text: root.ipAddress !== "" ? BoxStore.videoUriFor(root.ipAddress) : ""
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        elide: Text.ElideRight
    }
}
