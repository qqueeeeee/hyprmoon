import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 8

    property string feedback: ""

    Text {
        text: "ACTIONS"
        color: "#4a4f5a"
        font.family: "monospace"
        font.pixelSize: 10
        font.letterSpacing: 2
    }

    ActionRow {
        label: "LOCK"
        command: ["loginctl", "lock-session"]
    }

    ActionRow {
        label: "RELOAD HYPR"
        command: ["hyprctl", "reload"]
    }

    ActionRow {
        label: "SLEEP"
        command: ["systemctl", "suspend"]
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
        root.feedback = "applying...";
        actionProc.command = command;
        actionProc.running = true;
    }

    component ActionRow: Rectangle {
        property string label: ""
        property var command: []

        Layout.fillWidth: true
        height: 36
        color: actionArea.containsMouse ? "#1a1a1a" : "#0f0f0f"
        border.color: "#2a2e35"
        border.width: 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: label
            color: "#c8ccd4"
            font.family: "monospace"
            font.pixelSize: 13
        }

        MouseArea {
            id: actionArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.run(command, label)
        }
    }
}
