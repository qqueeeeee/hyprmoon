import Quickshell
import Quickshell.Io
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
    property bool present: true

    signal togglePopup()

    function fillBar(percent, segments) {
        var filled = Math.round((percent / 100) * segments);
        if (filled > segments) filled = segments;
        if (filled < 0) filled = 0;
        return "▆".repeat(filled) + "▁".repeat(segments - filled);
    }

    function charging() {
        return batteryStatus === "charging" || batteryStatus === "full";
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: !root.present ? "[BAT --]"
              : "[BAT " + root.fillBar(root.batteryPercent, 5) + (root.charging() ? " +" : " ") + root.batteryPercent + "]"
        color: root.popupOpen ? "#ffffff"
               : (root.batteryPercent > 0 && root.batteryPercent < 20 && !root.charging() ? "#ff5555" : "#c8ccd4")
        font.family: "monospace"
        font.pixelSize: 12
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.togglePopup()
    }

    Process {
        id: batteryProc
        command: ["sh", "-c", "if [ -r /sys/class/power_supply/BAT0/capacity ]; then b=BAT0; elif [ -r /sys/class/power_supply/BAT1/capacity ]; then b=BAT1; else b=; fi; if [ -n \"$b\" ]; then cat /sys/class/power_supply/$b/capacity; cat /sys/class/power_supply/$b/status; else echo missing; echo missing; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n");
                if ((parts[0] || "").trim() === "missing") {
                    root.present = false;
                    root.batteryPercent = 0;
                    return;
                }
                root.present = true;
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
        implicitWidth: 300
        implicitHeight: 200
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
                anchors.margins: 14
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "─ BATTERY"
                        color: "#4a4f5a"
                        font.family: "monospace"
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "[x]"
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
                    color: root.batteryPercent < 20 && !root.charging() ? "#ff5555" : "#c8ccd4"
                    font.family: "monospace"
                    font.pixelSize: 24
                }

                Text {
                    text: root.charging() ? "▲ " + root.batteryStatus : "▼ " + root.batteryStatus
                    color: "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 13
                }

                Text {
                    Layout.fillWidth: true
                    text: "[" + root.fillBar(root.batteryPercent, 20) + "]"
                    color: root.batteryPercent < 20 && !root.charging() ? "#ff5555" : "#c8ccd4"
                    font.family: "monospace"
                    font.pixelSize: 13
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
