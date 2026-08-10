import QtQuick
import DroidsManager
import "../Controls"

Item {
    id: root

    property string title: ""
    property string buttonText: ""
    property alias model: listView.model

    readonly property var columns: [
        { label: qsTr("Box Name"), w: 0.30 },
        { label: qsTr("Status"), w: 0.20 },
        { label: qsTr("IP Address"), w: 0.30 },
        { label: qsTr("Actions"), w: 0.20, right: true }
    ]

    signal connectClicked()
    signal toggleClicked(int index)
    signal removeClicked(int index)

    Item {
        id: tableHeader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 48

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXLarge
            font.weight: Font.DemiBold
        }

        PrimaryActionButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.connectClicked()

            Text {
                text: root.buttonText
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeNormal
                font.weight: Font.Medium
            }
        }
    }

    Rectangle {
        id: tableContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: tableHeader.bottom
        anchors.topMargin: Theme.spacingLg
        anchors.bottom: parent.bottom
        color: "transparent"
        radius: Theme.radiusSm
        border.width: 1
        border.color: Theme.borderStrong
        clip: true

        Rectangle {
            id: columnHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 44
            color: Theme.backgroundRaised
            radius: Theme.radiusSm

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.radiusSm
                color: Theme.backgroundRaised
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingXl
                anchors.rightMargin: Theme.spacingXl

                Repeater {
                    model: root.columns

                    Item {
                        required property var modelData
                        width: parent.width * modelData.w
                        height: parent.height

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: modelData.right ? parent.right : undefined
                            text: modelData.label
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Theme.borderRow
            }
        }

        Text {
            anchors.centerIn: parent
            visible: listView.count === 0
            text: qsTr("No boxes connected yet")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLarge
        }

        ListView {
            id: listView
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: columnHeader.bottom
            anchors.bottom: parent.bottom
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                width: listView.width
                height: 52

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingXl
                    anchors.rightMargin: Theme.spacingXl

                    Item {
                        width: parent.width * 0.30
                        height: parent.height

                        Row {
                            width: parent.width
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingSm

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18
                                height: 18
                                source: "qrc:/qt/qml/DroidsManager/assets/icons/icon_box.svg"
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.name
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeNormal
                                width: parent.width - x
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Item {
                        width: parent.width * 0.20
                        height: parent.height

                        DroidStatusBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            status: model.status
                        }
                    }

                    Item {
                        width: parent.width * 0.30
                        height: parent.height

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.ipAddress
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            width: parent.width
                            elide: Text.ElideRight
                        }
                    }

                    Item {
                        width: parent.width * 0.20
                        height: parent.height

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingSm

                            SecondaryActionButton {
                                onClicked: root.toggleClicked(model.index)

                                Text {
                                    text: model.status === DroidStatusBadge.Status.Connected
                                          ? qsTr("Disconnect") : qsTr("Connect")
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
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
                                    onClicked: root.removeClicked(model.index)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Theme.borderRow
                    visible: model.index < listView.count - 1
                }
            }
        }
    }
}
