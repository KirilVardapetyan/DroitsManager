import QtQuick
import QtQuick.Controls
import DroidsManager
import "qml/Components"
import "qml/Screens"

Window {
    id: window
    visible: true
    width: 1280
    height: 720
    title: qsTr("Droids Manager")
    color: Theme.backgroundPrimary

    property int currentNavIndex: 0

    Shortcut {
        sequence: "Ctrl+Q"
        onActivated: Qt.quit()
    }

    NavSidebar {
        id: navSidebar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        currentIndex: window.currentNavIndex
        z: 2

        onLiveMapClicked: {
            window.currentNavIndex = 0
            stackView.replace(null, liveMapScreen, {}, StackView.Immediate)
        }
        onDroidsClicked: {
            window.currentNavIndex = 1
            stackView.replace(null, droidsScreen, {}, StackView.Immediate)
        }
    }

    StackView {
        id: stackView
        anchors.left: navSidebar.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        initialItem: liveMapScreen
        pushEnter: Transition {}
        pushExit: Transition {}
        popEnter: Transition {}
        popExit: Transition {}
        replaceEnter: Transition {}
        replaceExit: Transition {}
    }

    Component {
        id: liveMapScreen
        LiveMapScreen {}
    }

    Component {
        id: droidsScreen
        DroidsScreen {}
    }
}
