import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 6
    width: 248
    Layout.preferredWidth: 248

    property int lastIdle: 0
    property int lastTotal: 0
    property int cpuPercent: 0
    property int ramPercent: 0
    property int diskPercent: 0
    property int tempC: 0
    property string uptimeText: "--"
    property var cpuHistory: []

    function fillBar(percent, segments) {
        var filled = Math.round((percent / 100) * segments);
        if (filled > segments) filled = segments;
        if (filled < 0) filled = 0;
        return "▆".repeat(filled) + "▁".repeat(segments - filled);
    }

    function sparkline(history, length) {
        var blocks = " ▁▂▃▄▅▆▇█";
        var out = "";
        var slice = history.slice(-length);
        for (var i = 0; i < slice.length; i++) {
            var v = Math.min(8, Math.round((slice[i] / 100) * 8));
            out += blocks.charAt(v);
        }
        while (out.length < length) out = " " + out;
        return out;
    }

    Text {
        text: "─ SYSTEM"
        color: "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 10
        font.letterSpacing: 2
    }

    // CPU with sparkline
    ColumnLayout {
        width: 248
        Layout.preferredWidth: 248
        spacing: 2

        Item {
            width: 248
            height: 18

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "CPU"
                color: "#4a4f5a"
                font.family: "monospace"
                font.pixelSize: 10
                font.letterSpacing: 2
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.cpuPercent + "%"
                color: root.cpuPercent >= 90 ? "#ff5555" : "#c8ccd4"
                font.family: "monospace"
                font.pixelSize: 13
            }
        }

        Text {
            Layout.fillWidth: true
            text: "[" + root.fillBar(root.cpuPercent, 22) + "]"
            color: root.cpuPercent >= 90 ? "#ff5555" : "#c8ccd4"
            font.family: "monospace"
            font.pixelSize: 12
        }

        Text {
            Layout.fillWidth: true
            text: " " + root.sparkline(root.cpuHistory, 22)
            color: "#c8ccd4"
            opacity: 0.6
            font.family: "monospace"
            font.pixelSize: 12
        }
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
        width: 248
        height: 18
        visible: root.tempC > 0

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "TEMP"
            color: "#4a4f5a"
            font.family: "monospace"
            font.pixelSize: 10
            font.letterSpacing: 2
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.tempC + "°C"
            color: root.tempC >= 80 ? "#ff5555" : "#c8ccd4"
            font.family: "monospace"
            font.pixelSize: 13
        }
    }

    Item {
        width: 248
        height: 18

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
        command: ["sh", "-c", "head -n1 /proc/stat; awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {print t, a}' /proc/meminfo; df -P / | awk 'NR==2 {print $5}'; cut -d. -f1 /proc/uptime; for f in /sys/class/thermal/thermal_zone*/temp; do [ -r \"$f\" ] && cat \"$f\" && break; done 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var cpu = (lines[0] || "").trim().split(/\s+/).slice(1).map(function(v) { return parseInt(v); });
                if (cpu.length >= 4) {
                    var idle = cpu[3] + (cpu[4] || 0);
                    var total = 0;
                    for (var i = 0; i < cpu.length; i++) total += cpu[i];
                    if (root.lastTotal > 0) {
                        var totalDelta = total - root.lastTotal;
                        var idleDelta = idle - root.lastIdle;
                        root.cpuPercent = totalDelta > 0 ? Math.round((1 - idleDelta / totalDelta) * 100) : 0;
                        var hist = root.cpuHistory.slice();
                        hist.push(root.cpuPercent);
                        while (hist.length > 30) hist.shift();
                        root.cpuHistory = hist;
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

                var tempRaw = parseInt(lines[4] || "0");
                if (tempRaw > 0) root.tempC = Math.round(tempRaw / 1000);
            }
        }
    }

    Component.onCompleted: statsProc.running = true

    Timer { interval: 2000; running: true; repeat: true; onTriggered: statsProc.running = true }

    component MetricRow: ColumnLayout {
        property string label: ""
        property string value: ""
        property int percent: 0

        spacing: 2
        width: 248
        Layout.preferredWidth: 248

        Item {
            width: 248
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

        Text {
            Layout.fillWidth: true
            text: "[" + fillBar(percent, 22) + "]"
            color: percent >= 90 ? "#ff5555" : "#c8ccd4"
            font.family: "monospace"
            font.pixelSize: 12
        }
    }
}
