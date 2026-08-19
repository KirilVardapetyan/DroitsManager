import QtQuick
import DroitsManager
import "../Controls"

Item {
    id: root

    property string title: ""
    property alias model: listView.model

    readonly property var columns: [
        { label: qsTr("Customer"), w: 0.16 },
        { label: qsTr("Pickup"), w: 0.17 },
        { label: qsTr("Destination"), w: 0.17 },
        { label: qsTr("Ordered"), w: 0.16 },
        { label: qsTr("Status"), w: 0.14 },
        { label: qsTr("Actions"), w: 0.20, right: true }
    ]

    signal startShippingClicked(int index)
    signal abortClicked(int index)

    function formatCoord(lat, lon) {
        return lat.toFixed(5) + ", " + lon.toFixed(5)
    }

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
            text: qsTr("No orders yet")
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
                        width: parent.width * 0.16
                        height: parent.height

                        Row {
                            width: parent.width
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingSm

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 18
                                height: 18
                                source: "qrc:/qt/qml/DroitsManager/assets/icons/icon_user.svg"
                                fillMode: Image.PreserveAspectFit
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.username
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeNormal
                                width: parent.width - x
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Item {
                        width: parent.width * 0.17
                        height: parent.height

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.formatCoord(model.startLat, model.startLon)
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            width: parent.width
                            elide: Text.ElideRight
                        }
                    }

                    Item {
                        width: parent.width * 0.17
                        height: parent.height

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.formatCoord(model.endLat, model.endLon)
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            width: parent.width
                            elide: Text.ElideRight
                        }
                    }

                    Item {
                        width: parent.width * 0.16
                        height: parent.height

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.orderedAt
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
                            width: parent.width
                            elide: Text.ElideRight
                        }
                    }

                    Item {
                        width: parent.width * 0.14
                        height: parent.height

                        OrderStatusBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            status: model.status
                        }
                    }

                    Item {
                        width: parent.width * 0.20
                        height: parent.height

                        PrimaryActionButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: model.status === OrderStatusBadge.Status.Pending
                            buttonHeight: 32
                            horizontalPadding: Theme.spacingMd
                            onClicked: root.startShippingClicked(model.index)

                            Text {
                                text: qsTr("Start Shipping")
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                            }
                        }

                        PrimaryActionButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: model.status === OrderStatusBadge.Status.InProcess
                                     || model.status === OrderStatusBadge.Status.Started
                            buttonHeight: 32
                            horizontalPadding: Theme.spacingMd
                            backgroundColor: Theme.error
                            hoverBackgroundColor: Theme.errorHover
                            pressedBackgroundColor: Theme.errorPressed
                            onClicked: root.abortClicked(model.index)

                            Text {
                                text: qsTr("Abort")
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: model.status === OrderStatusBadge.Status.Delivered
                            text: "—"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeNormal
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
