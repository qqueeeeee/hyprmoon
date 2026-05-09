import Quickshell.Io
import QtQuick

Item {
    id: root

    property string title: ""

    height: 28

    Text {
        anchors.centerIn: parent
        width: parent.width
        text: root.title || "desktop"
        color: root.title ? "#4a4f5a" : "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    Process {
        id: activeWindowProc
        command: ["sh", "-c", "hyprctl activewindow 2>/dev/null | awk -F': ' '/^[[:space:]]*title:/ {print $2; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.title = text.trim();
            }
        }
    }

    Component.onCompleted: activeWindowProc.running = true

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: activeWindowProc.running = true
    }
}
