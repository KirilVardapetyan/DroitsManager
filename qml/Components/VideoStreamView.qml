import QtQuick
import QtMultimedia
import DroitsManager

Rectangle {
    id: root

    property string streamUri: ""
    property bool active: visible

    width: 300
    height: 200
    radius: Theme.radiusMd
    color: "#0b0b0e"
    border.width: 1
    border.color: Theme.borderStrong
    clip: true

    BoxVideoReceiver {
        id: receiver
        uri: root.streamUri
        active: root.active && root.streamUri !== ""
        videoSink: videoOutput.videoSink
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacingSm
        visible: !receiver.receiving

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 34
            height: 24
            radius: Theme.radiusXs
            color: "transparent"
            border.width: 2
            border.color: Theme.textSecondary

            Rectangle {
                anchors.left: parent.right
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 12
                radius: 2
                color: Theme.textSecondary
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.streamUri === "" ? qsTr("VIDEO") : qsTr("WAITING FOR STREAM…")
            color: Theme.textSecondary
            font.family: "monospace"
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.DemiBold
        }
    }

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Theme.spacingSm
        spacing: Theme.spacingXs
        visible: receiver.receiving

        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.error

            SequentialAnimation on opacity {
                running: receiver.receiving
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.3; duration: 700 }
                NumberAnimation { from: 0.3; to: 1.0; duration: 700 }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("LIVE")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.Bold
            style: Text.Outline
            styleColor: "#000000"
        }
    }
}
