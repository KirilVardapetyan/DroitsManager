import QtQuick
import DroitsManager
import "../Controls"

ModalShell {
    id: root

    property string droneName: ""
    property string ipAddress: ""

    title: root.droneName !== "" ? qsTr("%1 — Live Video").arg(root.droneName) : qsTr("Live Video")
    modalWidth: 720

    function open(name, ipAddress) {
        root.droneName = name
        root.ipAddress = ipAddress
        root.visible = true
    }

    onClosed: {
        root.droneName = ""
        root.ipAddress = ""
    }

    Item {
        width: parent.width
        height: Math.round(width * 9 / 16)

        VideoStreamView {
            anchors.fill: parent
            streamUri: root.ipAddress !== "" ? DroneStore.videoUriFor(root.ipAddress) : ""
            active: root.visible && root.ipAddress !== ""
        }
    }

    Text {
        width: parent.width
        visible: root.ipAddress !== ""
        text: root.ipAddress !== "" ? DroneStore.videoUriFor(root.ipAddress) : ""
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSmall
        elide: Text.ElideRight
    }
}
