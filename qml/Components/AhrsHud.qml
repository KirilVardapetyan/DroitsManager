import QtQuick
import DroitsManager

Rectangle {
    id: root

    property real roll: 0
    property real pitch: 0
    property real yaw: 0
    property bool live: false

    readonly property real pxPerDegree: 2.4

    width: 300
    height: 200
    radius: Theme.radiusMd
    color: Qt.rgba(28 / 255, 28 / 255, 32 / 255, 0.92)
    border.width: 1
    border.color: Theme.borderStrong

    Item {
        id: horizonFrame
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingMd
        anchors.bottom: readouts.top
        anchors.bottomMargin: Theme.spacingMd
        clip: true

        Item {
            id: horizonRotor
            anchors.centerIn: parent
            width: horizonFrame.width * 2.2
            height: horizonFrame.height * 4
            rotation: -root.roll

            readonly property real horizonY: height / 2 + root.pitch * root.pxPerDegree

            Rectangle {
                id: sky
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: horizonRotor.horizonY
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#16283f" }
                    GradientStop { position: 1.0; color: "#2e5a8f" }
                }
            }

            Rectangle {
                id: ground
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: sky.bottom
                anchors.bottom: parent.bottom
                color: "#3d2b1a"
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                y: horizonRotor.horizonY - 1
                height: 2
                color: "#e8e8ec"
            }

            Repeater {
                model: [-20, -10, 10, 20]

                Item {
                    required property int modelData

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: horizonRotor.horizonY - modelData * root.pxPerDegree
                    width: Math.abs(modelData) === 20 ? 72 : 44
                    height: 1

                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(1, 1, 1, 0.55)
                    }

                    Text {
                        anchors.left: parent.right
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.abs(parent.modelData)
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.family: "monospace"
                        font.pixelSize: 9
                    }
                }
            }
        }

        // Fixed aircraft reference symbol.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenterOffset: -34
            width: 26
            height: 3
            radius: 1.5
            color: Theme.primary
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenterOffset: 34
            width: 26
            height: 3
            radius: 1.5
            color: Theme.primary
        }

        Rectangle {
            anchors.centerIn: parent
            width: 7
            height: 7
            radius: 3.5
            color: "transparent"
            border.width: 2
            border.color: Theme.primary
        }

        Rectangle {
            anchors.fill: parent
            visible: !root.live
            color: Qt.rgba(24 / 255, 24 / 255, 27 / 255, 0.75)

            Text {
                anchors.centerIn: parent
                text: qsTr("NO ATTITUDE DATA")
                color: Theme.textSecondary
                font.family: "monospace"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
            }
        }
    }

    Row {
        id: readouts
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingMd
        height: 30

        Repeater {
            model: [
                { label: qsTr("ROLL"), value: root.roll.toFixed(1) + "°" },
                { label: qsTr("PITCH"), value: root.pitch.toFixed(1) + "°" },
                { label: qsTr("HDG"), value: root.yaw.toFixed(0) + "°" }
            ]

            Column {
                required property var modelData

                width: readouts.width / 3
                spacing: 1

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: parent.modelData.label
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.live ? parent.modelData.value : "—"
                    color: Theme.textPrimary
                    font.family: "monospace"
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
