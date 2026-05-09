import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 8
    width: 228
    Layout.preferredWidth: 228

    property int lastIdle: 0
    property int lastTotal: 0
    property int cpuPercent: 0
    property int ramPercent: 0
    property int diskPercent: 0
    property string uptimeText: "--"

    Text {
        text: "SYSTEM"
        color: "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 10
        font.letterSpacing: 2
    }

    MetricRow {
        label: "CPU"
        value: root.cpuPercent + "%"
        percent: root.cpuPercent
    }

    MetricRow {
        label: "RAM"
        value: root.ramPercent + "%"
        percent: root.ramPercent
    }

    MetricRow {
        label: "DISK"
        value: root.diskPercent + "%"
        percent: root.diskPercent
    }

    Item {
        width: 228
        height: 24

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "UPTIME"
            color: "#4a4f5a"
            font.family: "monospace"
            font.pixelSize: 10
            font.letterSpacing: 2
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.uptimeText
            color: "#c8ccd4"
            font.family: "monospace"
            font.pixelSize: 13
        }
    }

    Process {
        id: statsProc
        command: ["sh", "-c", "head -n1 /proc/stat; awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {print t, a}' /proc/meminfo; df -P / | awk 'NR==2 {print $5}'; cut -d. -f1 /proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var cpu = (lines[0] || "").trim().split(/\s+/).slice(1).map(function(v) { return parseInt(v); });
                if (cpu.length >= 4) {
                    var idle = cpu[3] + (cpu[4] || 0);
                    var total = 0;
                    for (var i = 0; i < cpu.length; i++)
                        total += cpu[i];
                    if (root.lastTotal > 0) {
                        var totalDelta = total - root.lastTotal;
                        var idleDelta = idle - root.lastIdle;
                        root.cpuPercent = totalDelta > 0 ? Math.round((1 - idleDelta / totalDelta) * 100) : 0;
                    }
                    root.lastTotal = total;
                    root.lastIdle = idle;
                }

                var mem = (lines[1] || "").trim().split(/\s+/);
                if (mem.length >= 2) {
                    var totalMem = parseInt(mem[0]);
                    var availableMem = parseInt(mem[1]);
                    root.ramPercent = totalMem > 0 ? Math.round((1 - availableMem / totalMem) * 100) : 0;
                }

                root.diskPercent = parseInt((lines[2] || "0").replace("%", "")) || 0;

                var seconds = parseInt(lines[3] || "0");
                var hours = Math.floor(seconds / 3600);
                var minutes = Math.floor((seconds % 3600) / 60);
                root.uptimeText = hours + "h " + minutes + "m";
            }
        }
    }

    Component.onCompleted: statsProc.running = true

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: statsProc.running = true
    }

    component MetricRow: ColumnLayout {
        property string label: ""
        property string value: ""
        property int percent: 0

        spacing: 4
        width: 228
        Layout.preferredWidth: 228

        Item {
            width: 228
            height: 18

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: label
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                font.letterSpacing: 2
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: value
                color: percent >= 90 ? "#ff5555" : "#c8ccd4"
                font.family: "monospace"
                font.pixelSize: 13
            }
        }

        Rectangle {
            width: 228
            height: 4
            color: "#2a2e35"

            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, percent)) / 100
                height: parent.height
                color: percent >= 90 ? "#ff5555" : "#c8ccd4"
            }
        }
    }
}
