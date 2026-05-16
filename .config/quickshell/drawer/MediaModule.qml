import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 6
    width: 248
    Layout.preferredWidth: 248

    property string title: "no media"
    property string artist: ""
    property string status: ""
    property real positionUs: 0
    property real lengthUs: 0

    function fmtTime(us) {
        var s = Math.max(0, Math.round(us / 1000000));
        var m = Math.floor(s / 60);
        var rem = s % 60;
        return m + ":" + (rem < 10 ? "0" : "") + rem;
    }

    function fillBar(ratio, segments) {
        if (!isFinite(ratio)) ratio = 0;
        var filled = Math.round(ratio * segments);
        if (filled > segments) filled = segments;
        if (filled < 0) filled = 0;
        return "▆".repeat(filled) + "▁".repeat(segments - filled);
    }

    Text {
        text: "─ MEDIA"
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
        text: root.artist || (root.status ? "[" + root.status.toLowerCase() + "]" : "")
        color: "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 12
        elide: Text.ElideRight
        visible: !!text
    }

    Text {
        Layout.fillWidth: true
        visible: root.lengthUs > 0
        text: "[" + root.fillBar(root.positionUs / Math.max(1, root.lengthUs), 22) + "] "
              + root.fmtTime(root.positionUs) + "/" + root.fmtTime(root.lengthUs)
        color: "#c8ccd4"
        font.family: "monospace"
        font.pixelSize: 11
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

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
        command: ["sh", "-c", "playerctl metadata --format '{{title}}\\n{{artist}}\\n{{status}}\\n{{mpris:length}}\\n{{position}}' 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n");
                root.title = parts[0] || "no media";
                root.artist = parts[1] || "";
                root.status = parts[2] || "";
                root.lengthUs = parseInt(parts[3] || "0") || 0;
                root.positionUs = parseInt(parts[4] || "0") || 0;
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

    Timer { interval: 2000; running: true; repeat: true; onTriggered: mediaProc.running = true }

    component ActionCell: Rectangle {
        signal triggered()
        property string label: ""

        Layout.fillWidth: true
        height: 30
        color: actionArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
        border.color: "#2a2e35"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "[ " + label + " ]"
            color: "#c8ccd4"
            font.family: "monospace"
            font.pixelSize: 12
        }

        MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: triggered()
        }
    }
}
