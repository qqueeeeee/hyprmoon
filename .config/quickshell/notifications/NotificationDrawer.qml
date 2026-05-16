import Quickshell
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: drawerWindow

    property bool drawerOpen: false
    property bool drawerVisible: drawerOpen
    property var daemon: null

    required property var screen

    anchors {
        top: true
        right: true
        bottom: true
    }

    implicitWidth: 380
    visible: drawerVisible
    color: "#0f0f0f"
    exclusiveZone: 0  // overlay over windows, don't reserve space

    Item {
        id: drawerWrapper
        x: drawerOpen ? 0 : 380
        width: 380
        height: parent.height

        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: "#2a2e35"
        }

        // Header
        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 14
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 18

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "─ NOTIFICATIONS"
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                font.letterSpacing: 2
            }

            RowLayout {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    text: drawerWindow.daemon ? "[" + drawerWindow.daemon.historyCount + "]" : "[0]"
                    color: "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }

                Text {
                    text: drawerWindow.daemon && drawerWindow.daemon.dnd ? "[dnd:on]" : "[dnd:off]"
                    color: dndArea.containsMouse ? "#ffffff" : "#c8ccd4"
                    font.family: "monospace"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    MouseArea {
                        id: dndArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        onClicked: if (drawerWindow.daemon) drawerWindow.daemon.dnd = !drawerWindow.daemon.dnd
                    }
                }

                Text {
                    text: "[clear]"
                    color: clearArea.containsMouse ? "#ffffff" : "#c8ccd4"
                    font.family: "monospace"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    visible: drawerWindow.daemon && drawerWindow.daemon.historyCount > 0
                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        onClicked: if (drawerWindow.daemon) drawerWindow.daemon.clearAll()
                    }
                }
            }
        }

        // Empty state
        Text {
            visible: !drawerWindow.daemon || drawerWindow.daemon.historyCount === 0
            anchors.top: header.bottom
            anchors.topMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter
            text: "no notifications"
            color: "#4a4f5a"
            font.family: "monospace"
            font.pixelSize: 12
            font.letterSpacing: 2
        }

        // Notification list
        Flickable {
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: 14
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 14
            visible: drawerWindow.daemon && drawerWindow.daemon.historyCount > 0
            contentHeight: notifColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: notifColumn
                width: 346
                spacing: 8

                Repeater {
                    model: drawerWindow.daemon ? drawerWindow.daemon.history : null

                    delegate: Rectangle {
                        id: card
                        Layout.fillWidth: true
                        Layout.preferredHeight: cardLayout.implicitHeight + 16
                        color: cardArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
                        border.color: model.urgency === "2" ? "#ff5555" : "#2a2e35"
                        border.width: 1

                        ColumnLayout {
                            id: cardLayout
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.topMargin: 8
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "─ " + (model.appName || "?").toUpperCase()
                                    color: "#4a4f5a"
                                    font.family: "monospace"
                                    font.pixelSize: 10
                                    font.letterSpacing: 2
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: model.timeLabel || ""
                                    color: "#4a4f5a"
                                    font.family: "monospace"
                                    font.pixelSize: 10
                                }

                                Text {
                                    text: "[x]"
                                    color: dismissArea.containsMouse ? "#ffffff" : "#4a4f5a"
                                    font.family: "monospace"
                                    font.pixelSize: 10
                                    MouseArea {
                                        id: dismissArea
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        hoverEnabled: true
                                        onClicked: if (drawerWindow.daemon) drawerWindow.daemon.dismiss(model.notifId)
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.summary || ""
                                color: "#c8ccd4"
                                font.family: "monospace"
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.body || ""
                                color: "#c8ccd4"
                                opacity: 0.7
                                font.family: "monospace"
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                visible: !!model.body
                            }
                        }

                        MouseArea {
                            id: cardArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onClicked: function(mouse) { mouse.accepted = false }
                        }
                    }
                }
            }
        }
    }

    onDrawerOpenChanged: {
        if (drawerOpen) {
            drawerVisible = true;
            if (daemon) daemon.markRead();
        } else {
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 210
        onTriggered: if (!drawerWindow.drawerOpen) drawerWindow.drawerVisible = false
    }
}
