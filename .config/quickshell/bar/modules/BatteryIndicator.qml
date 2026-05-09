import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    height: 28
    implicitWidth: labelText.width + 12
    width: implicitWidth
    Layout.preferredWidth: implicitWidth

    required property var screen
    property string activePopup: ""
    property bool popupOpen: activePopup === "battery"
    property int batteryPercent: 0
    property string batteryStatus: "unknown"

    signal togglePopup()

    Text {
        id: labelText
        anchors.centerIn: parent
        text: batteryPercent > 0 ? batteryPercent + "%" : "BAT"
        color: root.popupOpen ? "#ffffff" : (batteryPercent > 0 && batteryPercent < 20 ? "#ff5555" : "#c8ccd4")
        font.family: "monospace"
        font.pixelSize: 12
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.togglePopup()
    }

    Process {
        id: batteryProc
        command: ["sh", "-c", "if [ -r /sys/class/power_supply/BAT0/capacity ]; then b=BAT0; elif [ -r /sys/class/power_supply/BAT1/capacity ]; then b=BAT1; else b=; fi; if [ -n \"$b\" ]; then cat /sys/class/power_supply/$b/capacity; cat /sys/class/power_supply/$b/status; else echo 0; echo unknown; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n");
                root.batteryPercent = Math.max(0, Math.min(100, parseInt(parts[0] || "0")));
                root.batteryStatus = (parts[1] || "unknown").trim().toLowerCase();
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: batteryProc.running = true
    }

    PanelWindow {
        id: popup
        screen: root.screen
        visible: root.popupOpen
        implicitWidth: 280
        implicitHeight: 186
        color: "#0f0f0f"
        anchors.top: true
        anchors.right: true
        margins.top: 28

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: root.togglePopup()
        }

        Rectangle {
            anchors.fill: parent
            color: "#0f0f0f"
            border.color: "#2a2e35"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "BATTERY"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "✕"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.togglePopup()
                        }
                    }
                }

                Text {
                    text: root.batteryPercent + "%"
                    color: root.batteryPercent < 20 ? "#ff5555" : "#c8ccd4"
                    font.family: "monospace"
                    font.pixelSize: 20
                }

                Text {
                    text: root.batteryStatus
                    color: "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 13
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    color: "#2a2e35"

                    Rectangle {
                        width: parent.width * root.batteryPercent / 100
                        height: parent.height
                        color: root.batteryPercent < 20 ? "#ff5555" : "#c8ccd4"
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
