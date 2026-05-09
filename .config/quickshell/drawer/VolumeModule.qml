import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    spacing: 8

    Text {
        text: "VOLUME"
        font.family: "monospace"
        font.pixelSize: 10
        color: "#4a4f5a"
        font.letterSpacing: 2
    }

    Text {
        id: volumePercent
        text: "--%"
        font.family: "monospace"
        font.pixelSize: 13
        color: "#c8ccd4"
    }

    Slider {
        id: volumeSlider
        orientation: Qt.Horizontal
        from: 0
        to: 100
        value: 0
        stepSize: 1
        width: 228

        background: Rectangle {
            width: parent.width
            height: 4
            color: "#2a2e35"
            radius: 0
        }

        handle: Rectangle {
            width: 14
            height: 14
            color: "#c8ccd4"
        }

        onMoved: {
            volumeStatus.text = "applying...";
            volSetProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", Math.round(value) + "%"];
            volSetProc.running = true;
        }
    }

    Rectangle {
        id: muteButton
        width: 228
        height: 36
        color: muteButtonText.text === "UNMUTE" || muteArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
        border.color: "#2a2e35"
        border.width: 1

        Text {
            id: muteButtonText
            anchors.centerIn: parent
            text: "MUTE"
            font.family: "monospace"
            font.pixelSize: 12
            color: "#c8ccd4"
        }

        MouseArea {
            id: muteArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                muteButtonText.text = "applying...";
                muteProc.running = true;
            }
        }
    }

    Text {
        id: volumeStatus
        text: ""
        font.family: "monospace"
        font.pixelSize: 10
        color: "#4a4f5a"
    }

    property int volumePercentValue: 0

    Process {
        id: volSetProc
        onExited: refreshVolume()
    }

    Process {
        id: muteProc
        command: ["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]
        onExited: refreshVolume()
    }

    Process {
        id: volRefreshProc
        command: ["sh", "-c", "pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+(?=%)' | head -1; pactl get-sink-mute @DEFAULT_SINK@"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split("\n");
                var vol = parts[0] ? parseInt(parts[0].trim()) : 0;
                var muteStatus = parts[1] ? parts[1].trim() : "";
                var isMuted = muteStatus.indexOf("yes") !== -1;
                volumePercentValue = isMuted ? 0 : vol;
                volumePercent.text = isMuted ? "MUTED" : vol + "%";
                volumeSlider.value = vol;
                muteButtonText.text = isMuted ? "UNMUTE" : "MUTE";
                volumeStatus.text = "";
            }
        }
    }

    function refreshVolume() {
        volRefreshProc.running = true;
    }

    Component.onCompleted: refreshVolume()

    WheelHandler {
        onWheel: {
            volumeStatus.text = "applying...";
            if (wheel.angleDelta.y > 0) {
                volSetProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", "+5%"];
            } else {
                volSetProc.command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", "-5%"];
            }
            volSetProc.running = true;
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: refreshVolume()
    }
}
