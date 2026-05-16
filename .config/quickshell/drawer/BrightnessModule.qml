import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 6
    width: 248
    Layout.preferredWidth: 248

    property int currentBrightness: 0
    property int maxBrightness: 1
    property int percent: maxBrightness > 0 ? Math.round(currentBrightness / maxBrightness * 100) : 0
    property bool present: false

    signal externalChange()

    function fillBar(percent, segments) {
        var filled = Math.round((percent / 100) * segments);
        if (filled > segments) filled = segments;
        if (filled < 0) filled = 0;
        return "▆".repeat(filled) + "▁".repeat(segments - filled);
    }

    Text {
        text: "─ BRIGHTNESS"
        color: "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 10
        font.letterSpacing: 2
    }

    Item {
        width: 248
        height: 18
        visible: root.present

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "SCREEN"
            color: "#4a4f5a"
            font.family: "monospace"
            font.pixelSize: 10
            font.letterSpacing: 2
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.percent + "%"
            color: "#c8ccd4"
            font.family: "monospace"
            font.pixelSize: 13
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.present
        text: "[" + root.fillBar(root.percent, 22) + "]"
        color: "#c8ccd4"
        font.family: "monospace"
        font.pixelSize: 12

        MouseArea {
            anchors.fill: parent
            onClicked: function(mouse) {
                var newPct = Math.round(mouse.x / width * 100);
                newPct = Math.max(1, Math.min(100, newPct));
                root.setBrightness(newPct);
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        visible: root.present

        Rectangle {
            Layout.fillWidth: true
            height: 26
            color: dnArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
            border.color: "#2a2e35"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "[ -10 ]"
                color: "#c8ccd4"
                font.family: "monospace"
                font.pixelSize: 13
            }

            MouseArea {
                id: dnArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.setBrightness(Math.max(1, root.percent - 10))
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 26
            color: upArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
            border.color: "#2a2e35"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "[ +10 ]"
                color: "#c8ccd4"
                font.family: "monospace"
                font.pixelSize: 13
            }

            MouseArea {
                id: upArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.setBrightness(Math.min(100, root.percent + 10))
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: !root.present
        text: "  no backlight detected"
        color: "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 12
    }

    Process {
        id: readProc
        property bool firstRun: true
        command: ["sh", "-c", "dir=$(ls -d /sys/class/backlight/*/ 2>/dev/null | head -1); if [ -n \"$dir\" ]; then cat \"${dir}brightness\"; cat \"${dir}max_brightness\"; else echo missing; echo missing; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                if ((lines[0] || "").trim() === "missing") {
                    root.present = false;
                    return;
                }
                var newCur = parseInt(lines[0]) || 0;
                var newMax = parseInt(lines[1]) || 1;
                var changed = !readProc.firstRun && (newCur !== root.currentBrightness);
                root.currentBrightness = newCur;
                root.maxBrightness = newMax;
                root.present = true;
                if (changed) root.externalChange();
                readProc.firstRun = false;
            }
        }
    }

    Process {
        id: setProc
        onExited: readProc.running = true
    }

    function setBrightness(percent) {
        setProc.command = ["brightnessctl", "s", percent + "%"];
        setProc.running = true;
    }

    Component.onCompleted: readProc.running = true
    Timer { interval: 3000; running: true; repeat: true; onTriggered: readProc.running = true }
}
