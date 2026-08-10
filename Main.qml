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

    readonly property var sectionNames: [
        qsTr("Dashboard"),
        qsTr("Droids"),
        qsTr("Missions"),
        qsTr("Monitoring"),
        qsTr("Settings")
    ]

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

        onDashboardClicked: window.currentNavIndex = 0
        onDroidsClicked: window.currentNavIndex = 1
        onMissionsClicked: window.currentNavIndex = 2
        onMonitoringClicked: window.currentNavIndex = 3
        onSettingsClicked: window.currentNavIndex = 4
    }

    StackView {
        id: stackView
        anchors.left: navSidebar.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        initialItem: mainScreen
        pushEnter: Transition {}
        pushExit: Transition {}
        popEnter: Transition {}
        popExit: Transition {}
        replaceEnter: Transition {}
        replaceExit: Transition {}
    }

    Component {
        id: mainScreen
        MainScreen {
            sectionName: window.sectionNames[window.currentNavIndex]
        }
    }
}
