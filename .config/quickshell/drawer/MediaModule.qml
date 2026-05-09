import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 8

    property string title: "no media"
    property string artist: ""
    property string status: ""

    Text {
        text: "MEDIA"
        color: "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 10
        font.letterSpacing: 2
    }

    Text {
        Layout.fillWidth: true
        text: root.title
        color: root.title === "no media" ? "#4a4f5a" : "#c8ccd4"
        font.family: "monospace"
        font.pixelSize: 13
        elide: Text.ElideRight
    }

    Text {
        Layout.fillWidth: true
        text: root.artist || root.status
        color: "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 13
        elide: Text.ElideRight
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        ActionCell {
            label: "PREV"
            onTriggered: root.runAction("previous")
        }

        ActionCell {
            label: root.status === "Playing" ? "PAUSE" : "PLAY"
            onTriggered: root.runAction("play-pause")
        }

        ActionCell {
            label: "NEXT"
            onTriggered: root.runAction("next")
        }
    }

    Process {
        id: mediaProc
        command: ["sh", "-c", "playerctl metadata --format '{{title}}\\n{{artist}}\\n{{status}}' 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n");
                root.title = parts[0] || "no media";
                root.artist = parts[1] || "";
                root.status = parts[2] || "";
            }
        }
    }

    Process {
        id: mediaActionProc
        onExited: mediaProc.running = true
    }

    function runAction(action) {
        mediaActionProc.command = ["playerctl", action];
        mediaActionProc.running = true;
    }

    Component.onCompleted: mediaProc.running = true

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: mediaProc.running = true
    }

    component ActionCell: Rectangle {
        signal triggered()
        property string label: ""

        Layout.fillWidth: true
        height: 36
        color: actionArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
        border.color: "#2a2e35"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: label
            color: "#c8ccd4"
            font.family: "monospace"
            font.pixelSize: 13
        }

        MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: triggered()
        }
    }
}
