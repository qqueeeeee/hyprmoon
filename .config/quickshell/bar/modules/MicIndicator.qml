import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Renders only when the mic is muted, so the bar stays uncluttered.
Item {
    id: root
    required property var screen
    property bool muted: false

    implicitHeight: 28
    implicitWidth: muted ? labelText.width + 8 : 0
    visible: muted

    Text {
        id: labelText
        anchors.centerIn: parent
        text: "[mic-]"
        color: "#ff5555"
        font.family: "monospace"
        font.pixelSize: 12
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.muted
        onClicked: toggleProc.running = true
    }

    Process {
        id: refreshProc
        command: ["sh", "-c", "pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.muted = text.indexOf("yes") !== -1;
            }
        }
    }

    Process {
        id: toggleProc
        command: ["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"]
        onExited: refreshProc.running = true
    }

    Process {
        id: subscribeProc
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                if (line.indexOf("on source #") !== -1)
                    refreshProc.running = true;
            }
        }
    }

    Component.onCompleted: refreshProc.running = true
    Timer { interval: 10000; running: true; repeat: true; onTriggered: refreshProc.running = true }
}
