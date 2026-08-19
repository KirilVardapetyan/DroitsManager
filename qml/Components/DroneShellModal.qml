import QtQuick
import DroitsManager
import "../Controls"

ModalShell {
    id: root

    property string droneName: ""
    property string ipAddress: ""

    readonly property var commandTemplates: [
        { name: "ping", line: '{"command": "ping"}' },
        { name: "status", line: '{"command": "status"}' },
        { name: "get_attitude", line: '{"command": "get_attitude"}' },
        { name: "get_gps", line: '{"command": "get_gps"}' },
        { name: "get_arm_state", line: '{"command": "get_arm_state"}' },
        { name: "get_prearm_errors", line: '{"command": "get_prearm_errors"}' },
        { name: "get_mission", line: '{"command": "get_mission"}' },
        { name: "get_flight_mode", line: '{"command": "get_flight_mode"}' },
        { name: "set_flight_mode", line: '{"command": "set_flight_mode", "params": {"mode": "GUIDED"}}' },
        { name: "arm", line: '{"command": "arm"}' },
        { name: "disarm", line: '{"command": "disarm"}' },
        { name: "upload_mission", line: '{"command": "upload_mission", "params": {"waypoints": [{"latitude": 40.1800, "longitude": 44.5000, "altitude": 50}, {"command": "rtl"}]}}' }
    ]

    title: root.droneName !== "" ? qsTr("%1 — Shell").arg(root.droneName) : qsTr("Drone Shell")
    modalWidth: 760
    closeOnBackdropClick: false

    function open(name, ipAddress) {
        root.droneName = name
        root.ipAddress = ipAddress
        logModel.clear()
        commandInput.text = ""
        shell.host = ipAddress
        shell.openConnection()
        root.visible = true
        commandInput.forceInputFocus()
    }

    onClosed: {
        shell.closeConnection()
        root.droneName = ""
        root.ipAddress = ""
    }

    function appendLog(kind, text) {
        logModel.append({ kind: kind, text: text })
        logView.positionViewAtEnd()
    }

    function send() {
        if (!shell.connected || shell.busy || commandInput.text.trim() === "")
            return
        shell.sendLine(commandInput.text)
    }

    DroneShell {
        id: shell

        onLineSent: function(line) { root.appendLog("sent", line) }
        onLineReceived: function(line) { root.appendLog("recv", line) }
        onShellError: function(message) { root.appendLog("error", message) }
    }

    Item {
        width: parent.width
        height: statusText.implicitHeight

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingSm

            Rectangle {
                width: 8
                height: 8
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: shell.connected ? Theme.success
                     : shell.connecting ? Theme.warning : Theme.error
            }

            Text {
                id: statusText
                anchors.verticalCenter: parent.verticalCenter
                text: (shell.connected ? qsTr("Connected") :
                       shell.connecting ? qsTr("Connecting…") : qsTr("Disconnected"))
                      + "  ·  " + root.ipAddress + ":5555"
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        SecondaryActionButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !shell.connected && !shell.connecting
            onClicked: shell.openConnection()

            Text {
                text: qsTr("Reconnect")
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 300
        radius: Theme.radiusSm
        color: Theme.backgroundPrimary
        border.width: 1
        border.color: Theme.borderStrong
        clip: true

        ListModel { id: logModel }

        Text {
            anchors.centerIn: parent
            visible: logModel.count === 0
            text: qsTr("Pick a command below or type a raw JSON request")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
        }

        ListView {
            id: logView
            anchors.fill: parent
            anchors.margins: Theme.spacingMd
            model: logModel
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: Theme.spacingXs

            delegate: Row {
                width: logView.width
                spacing: Theme.spacingSm

                Text {
                    text: model.kind === "sent" ? "→" : model.kind === "recv" ? "←" : "✕"
                    color: model.kind === "sent" ? Theme.accent
                         : model.kind === "recv" ? Theme.success : Theme.error
                    font.family: "monospace"
                    font.pixelSize: Theme.fontSizeSmall
                }

                TextEdit {
                    width: parent.width - x
                    text: model.text
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.WrapAnywhere
                    color: model.kind === "error" ? Theme.error : Theme.textPrimary
                    selectionColor: Theme.primary
                    font.family: "monospace"
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }
    }

    Flow {
        width: parent.width
        spacing: Theme.spacingXs

        Repeater {
            model: root.commandTemplates

            Rectangle {
                id: chip

                required property var modelData

                width: chipText.width + Theme.spacingMd * 2
                height: 26
                radius: 13
                color: chipArea.containsMouse ? Theme.hoverLight : Theme.backgroundSecondary
                border.width: 1
                border.color: Theme.borderPrimary

                Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: chip.modelData.name
                    color: Theme.textPrimary
                    font.family: "monospace"
                    font.pixelSize: Theme.fontSizeSmall
                }

                MouseArea {
                    id: chipArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        commandInput.text = chip.modelData.line
                        commandInput.forceInputFocus()
                    }
                }
            }
        }
    }

    Row {
        width: parent.width
        spacing: Theme.spacingSm

        AppTextField {
            id: commandInput
            width: parent.width - sendButton.width - Theme.spacingSm
            placeholderText: qsTr('{"command": "ping"}')
            onAccepted: root.send()
        }

        PrimaryActionButton {
            id: sendButton
            enabled: shell.connected && !shell.busy && commandInput.text.trim() !== ""
            onClicked: root.send()

            Text {
                text: shell.busy ? qsTr("Waiting…") : qsTr("Send")
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Font.Medium
            }
        }
    }
}
