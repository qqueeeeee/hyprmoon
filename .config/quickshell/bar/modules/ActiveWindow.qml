import Quickshell.Io
import QtQuick

Item {
    id: root

    property string title: ""
    property string appClass: ""

    height: 28

    Text {
        anchors.centerIn: parent
        width: parent.width
        text: root.title ? "~ " + root.title : "~ desktop"
        color: root.title ? "#c8ccd4" : "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    Process {
        id: activeWindowProc
        command: ["sh", "-c", "hyprctl activewindow 2>/dev/null | awk -F': ' '/^[[:space:]]*(title|class):/ {print $2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n");
                root.appClass = (parts[0] || "").trim();
                root.title = (parts[1] || "").trim();
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
