import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: 4

    Text {
        text: "BATTERY"
        font.family: "monospace"
        font.pixelSize: 10
        font.letterSpacing: 2
        color: "#4a4f5a"
    }

    Text {
        id: batteryText
        text: "--%"
        font.family: "monospace"
        font.pixelSize: 13
        color: "#c8ccd4"
    }

    property int batteryPercent: 0

    Rectangle {
        id: batteryTrack
        width: 228
        height: 6
        color: "#2a2e35"

        Rectangle {
            id: batteryFill
            height: parent.height
            color: batteryPercent > 20 ? "#c8ccd4" : "#ff5555"
            width: batteryPercent * 2.28
        }
    }

    Process {
        id: batteryProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo '?'; cat /sys/class/power_supply/BAT0/status 2>/dev/null || cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo 'unknown'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n")
                var capacity = parts[0] ? parseInt(parts[0].trim()) : 0
                if (isNaN(capacity))
                    capacity = 0
                var status = parts[1] ? parts[1].trim().toLowerCase() : ""
                batteryPercent = capacity
                batteryText.text = capacity + "% " + status
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: batteryProc.running = true
    }
}
