import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 6
    width: 248
    Layout.preferredWidth: 248

    property string feedback: ""

    Text {
        text: "─ ACTIONS"
        color: "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 10
        font.letterSpacing: 2
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 6
        rowSpacing: 6

        ActionCell {
            label: "LOCK"
            shortcut: "L"
            command: ["loginctl", "lock-session"]
        }

        ActionCell {
            label: "POWER"
            shortcut: "P"
            command: ["qs", "ipc", "call", "power", "toggle"]
        }

        ActionCell {
            label: "RELOAD"
            shortcut: "R"
            command: ["hyprctl", "reload"]
        }

        ActionCell {
            label: "SCREENSHOT"
            shortcut: "S"
            command: ["sh", "-c", "grim -g \"$(slurp)\" - | wl-copy"]
        }

        ActionCell {
            label: "WALLPAPER"
            shortcut: "W"
            command: ["qs", "ipc", "call", "wallpaper", "toggle"]
        }

        ActionCell {
            label: "LAUNCHER"
            shortcut: "A"
            command: ["qs", "ipc", "call", "launcher", "toggle"]
        }
    }

    Text {
        Layout.fillWidth: true
        text: root.feedback
        color: "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 10
        font.letterSpacing: 2
    }

    Process {
        id: actionProc
        onExited: feedbackTimer.restart()
    }

    Timer {
        id: feedbackTimer
        interval: 1800
        onTriggered: root.feedback = ""
    }

    function run(command, label) {
        root.feedback = "▶ " + label.toLowerCase();
        actionProc.command = command;
        actionProc.running = true;
    }

    component ActionCell: Rectangle {
        property string label: ""
        property string shortcut: ""
        property var command: []

        Layout.fillWidth: true
        Layout.preferredHeight: 30
        color: actionArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
        border.color: "#2a2e35"
        border.width: 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "[" + shortcut + "] " + label
            color: "#c8ccd4"
            font.family: "monospace"
            font.pixelSize: 12
        }

        MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.run(command, label)
        }
    }
}
