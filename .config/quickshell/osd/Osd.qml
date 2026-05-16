import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Bottom-center on-screen display for volume + brightness changes.
PanelWindow {
    id: root
    required property var screen

    color: "transparent"
    anchors.bottom: true
    exclusiveZone: 0  // overlay, don't shrink other windows

    implicitWidth: 320
    implicitHeight: 72
    margins.bottom: 80
    visible: showState

    property bool showState: false
    property string mode: "volume"  // "volume" | "brightness" | "mic"
    property int value: 0
    property bool muted: false

    function show(mode, value, muted) {
        root.mode = mode;
        root.value = value;
        root.muted = !!muted;
        root.showState = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: root.showState = false
    }

    function fillBar(percent, segments) {
        var filled = Math.round((percent / 100) * segments);
        if (filled > segments) filled = segments;
        if (filled < 0) filled = 0;
        return "▆".repeat(filled) + "▁".repeat(segments - filled);
    }

    function modeLabel() {
        if (root.mode === "brightness") return "BRIGHTNESS";
        if (root.mode === "mic") return "MIC";
        return "VOLUME";
    }

    function modeSymbol() {
        if (root.mode === "brightness") return "*";
        if (root.mode === "mic") return "ψ";
        return "♪";
    }

    Rectangle {
        anchors.fill: parent
        color: "#0f0f0f"
        border.color: "#2a2e35"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "─ " + root.modeLabel()
                    color: "#4a4f5a"
                    font.family: "monospace"
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.muted ? "MUTED" : root.value + "%"
                    color: root.muted ? "#ff5555" : "#c8ccd4"
                    font.family: "monospace"
                    font.pixelSize: 12
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.modeSymbol() + " [" + root.fillBar(root.muted ? 0 : root.value, 28) + "]"
                color: root.muted ? "#ff5555" : "#c8ccd4"
                font.family: "monospace"
                font.pixelSize: 14
            }
        }
    }

}
