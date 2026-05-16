import Quickshell
import QtQuick
import QtQuick.Layouts

// Per-screen layer with a column of toast cards (top-right, under the bar).
PanelWindow {
    id: root
    required property var screen
    required property var daemon

    color: "transparent"
    exclusiveZone: 0  // overlay, don't shrink other windows

    anchors {
        top: true
        right: true
    }

    implicitWidth: 360
    implicitHeight: Math.max(1, toastColumn.implicitHeight + 28)
    margins.top: 0
    visible: daemon && daemon.toasts.count > 0

    Item {
        anchors.fill: parent

        ColumnLayout {
            id: toastColumn
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 8
            anchors.topMargin: 36
            spacing: 6
            width: 340

            Repeater {
                model: root.daemon ? root.daemon.toasts : null
                delegate: Rectangle {
                    id: toast
                    Layout.fillWidth: true
                    Layout.preferredHeight: toastBody.implicitHeight + 30
                    color: "#0f0f0f"
                    border.color: model.urgency === "2" ? "#ff5555" : "#2a2e35"
                    border.width: 1
                    opacity: 0
                    transform: Translate { id: tr; x: 24 }

                    Component.onCompleted: {
                        opacity = 1;
                        tr.x = 0;
                        dismissTimer.restart();
                    }

                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    Timer {
                        id: dismissTimer
                        interval: model.urgency === "2" ? 12000 : 6000
                        onTriggered: if (root.daemon) root.daemon.dismissToast(model.notifId)
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "─ " + (model.appName || "?").toUpperCase()
                                color: "#4a4f5a"
                                font.family: "monospace"
                                font.pixelSize: 10
                                font.letterSpacing: 2
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "[x]"
                                color: closeArea.containsMouse ? "#ffffff" : "#4a4f5a"
                                font.family: "monospace"
                                font.pixelSize: 10
                                MouseArea {
                                    id: closeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: if (root.daemon) root.daemon.dismissToast(model.notifId)
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: model.summary || ""
                            color: "#c8ccd4"
                            font.family: "monospace"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        Text {
                            id: toastBody
                            Layout.fillWidth: true
                            text: model.body || ""
                            color: "#c8ccd4"
                            opacity: 0.7
                            font.family: "monospace"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            visible: !!model.body
                            maximumLineCount: 4
                        }
                    }
                }
            }
        }
    }
}
