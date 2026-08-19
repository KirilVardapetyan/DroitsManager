import QtQuick
import DroitsManager

// Slide-to-confirm control: drag the knob all the way right and release to
// trigger. Deliberate friction for an action that arms a real aircraft.
Rectangle {
    id: root

    property bool busy: false
    property bool completed: false

    readonly property real knobMargin: 4
    readonly property real maxKnobX: width - knob.width - knobMargin
    readonly property real progress: (knob.x - knobMargin) / (maxKnobX - knobMargin)

    signal activated()

    function reset() {
        completed = false
        knob.x = knobMargin
    }

    height: 56
    radius: height / 2
    color: Qt.rgba(28 / 255, 28 / 255, 32 / 255, 0.92)
    border.width: 1
    border.color: root.completed ? Theme.success : Theme.borderStrong

    onBusyChanged: if (busy) knob.x = maxKnobX
    onCompletedChanged: if (completed) knob.x = maxKnobX

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: knob.x + knob.width
        radius: root.radius
        color: root.completed ? Theme.successTint
             : Qt.rgba(249 / 255, 115 / 255, 22 / 255, 0.18 + root.progress * 0.14)
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingXl
        anchors.verticalCenter: parent.verticalCenter
        text: root.completed ? qsTr("SHIPPING")
            : root.busy ? qsTr("STARTING…") : qsTr("SHIP »")
        color: root.completed ? Theme.success
             : root.busy ? Theme.textPrimary : Theme.textSecondary
        opacity: root.completed || root.busy ? 1.0 : 1.0 - root.progress * 0.8
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeNormal
        font.weight: Font.DemiBold
        font.letterSpacing: 2
    }

    Rectangle {
        id: knob
        x: root.knobMargin
        anchors.verticalCenter: parent.verticalCenter
        width: root.height - root.knobMargin * 2
        height: width
        radius: width / 2
        color: root.completed ? Theme.success
             : knobArea.pressed ? Theme.primaryHover : Theme.primary

        Behavior on x {
            enabled: !knobArea.drag.active
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        Text {
            anchors.centerIn: parent
            text: root.completed ? "✓" : "»"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXLarge
            font.weight: Font.Bold
        }

        MouseArea {
            id: knobArea
            anchors.fill: parent
            enabled: !root.busy && !root.completed
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            drag.target: knob
            drag.axis: Drag.XAxis
            drag.minimumX: root.knobMargin
            drag.maximumX: root.maxKnobX

            onReleased: {
                if (root.progress >= 0.92)
                    root.activated()
                else
                    knob.x = root.knobMargin
            }
        }
    }
}
